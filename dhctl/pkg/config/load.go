// Copyright 2021 Flant JSC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"
	"sync"

	"github.com/go-openapi/spec"
	"github.com/go-openapi/strfmt"
	"github.com/go-openapi/validate"
	"github.com/go-openapi/validate/post"
	"github.com/hashicorp/go-multierror"
	"sigs.k8s.io/yaml"

	"github.com/deckhouse/deckhouse/dhctl/pkg/log"
)

type SchemaStore struct {
	cache              map[SchemaIndex]*spec.Schema
	moduleConfigsCache map[string]*spec.Schema
}

var once sync.Once

var store *SchemaStore

func NewSchemaStore(paths ...string) *SchemaStore {
	paths = append([]string{candiDir}, paths...)

	pathsStr := strings.TrimSpace(os.Getenv("DHCTL_CLI_ADDITIONAL_SCHEMAS_PATHS"))
	if pathsStr != "" {
		pathsNoTrimmed := strings.Split(pathsStr, ",")
		for _, p := range pathsNoTrimmed {
			paths = append(paths, strings.TrimSpace(p))
		}
	}

	return newOnceSchemaStore(paths)
}

func newSchemaStore(schemasDir []string) *SchemaStore {
	st := &SchemaStore{
		cache:              make(map[SchemaIndex]*spec.Schema),
		moduleConfigsCache: make(map[string]*spec.Schema),
	}

	walkFunc := func(path string, info os.FileInfo, err error) error {
		if info == nil {
			return nil
		}

		switch info.Name() {
		case "init_configuration.yaml", "cluster_configuration.yaml", "static_cluster_configuration.yaml", "cloud_discovery_data.yaml", "cloud_provider_discovery_data.yaml":
			uploadError := st.UploadByPath(path)
			if uploadError != nil {
				return uploadError
			}
		}

		return nil
	}

	for _, d := range schemasDir {
		err := filepath.Walk(d, walkFunc)
		if err != nil {
			panic(err)
		}
	}

	entries, err := os.ReadDir(modulesDir)
	if err != nil {
		// autoconverger and state exporter do not contains module dir
		log.WarnF("Modules dir not found")
		return st
	}

	loadConfigValuesSchema := func(path string, moduleName string) error {
		content, err := os.ReadFile(path)
		if err == nil {
			schema := new(spec.Schema)

			if err := yaml.Unmarshal(content, schema); err != nil {
				return err
			}

			err = spec.ExpandSchema(schema, schema, nil)
			if err != nil {
				return err
			}
			st.moduleConfigsCache[moduleName] = schema
		} else if errors.Is(err, os.ErrNotExist) {
			log.DebugF("openapi spec not found for module %s", moduleName)
		} else {
			return err
		}

		return nil
	}

	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		name := e.Name()
		moduleName := strings.TrimLeft(name, "01234567890-")
		p := path.Join(modulesDir, name, "openapi", "config-values.yaml")
		if err := loadConfigValuesSchema(p, moduleName); err != nil {
			// We don't expect panic here our logger does not support log.Fatal
			panic(err)
		}
	}

	err = loadConfigValuesSchema(path.Join(globalHooksModule, "openapi", "config-values.yaml"), "global")
	if err != nil {
		// We don't expect panic here our logger does not support log.Fatal
		panic(err)
	}

	return st
}

func newOnceSchemaStore(schemasDir []string) *SchemaStore {
	once.Do(func() {
		store = newSchemaStore(schemasDir)
	})
	return store
}

func (s *SchemaStore) Get(index *SchemaIndex) *spec.Schema {
	return s.cache[*index]
}

func (s *SchemaStore) HasSchemaForModuleConfig(name string) bool {
	_, ok := s.moduleConfigsCache[name]
	return ok
}

func (s *SchemaStore) GetModuleConfigVersion(name string) int {
	schema, ok := s.moduleConfigsCache[name]
	if ok {
		if len(schema.VendorExtensible.Extensions) > 0 {
			v, ok := schema.VendorExtensible.Extensions["x-config-version"]
			if ok {
				return int(v.(float64))
			}
		}
		return 1
	}

	return 1
}

func (s *SchemaStore) Validate(doc *[]byte) (*SchemaIndex, error) {
	var index SchemaIndex

	err := yaml.Unmarshal(*doc, &index)
	if err != nil {
		return nil, fmt.Errorf("json unmarshal: %v", err)
	}

	err = s.ValidateWithIndex(&index, doc)
	return &index, err
}

// v1alpha1 was changed to v1 in-place. To keep the backward compatibility we check old and new schemas
func (s *SchemaStore) getV1alpha1CompatibilitySchema(index *SchemaIndex) *spec.Schema {
	schema := s.Get(index)
	if schema == nil && index.Version == "deckhouse.io/v1alpha1" {
		index.Version = "deckhouse.io/v1"
		return s.Get(index)
	}

	return schema
}

func (s *SchemaStore) ValidateWithIndex(index *SchemaIndex, doc *[]byte) error {
	if !index.IsValid() {
		return fmt.Errorf(
			"document must contain \"kind\" and \"apiVersion\" fields:\n\tapiVersion: %s\n\tkind: %s\n\n%s",
			index.Version, index.Kind, string(*doc),
		)
	}

	docForValidate := *doc

	var schema *spec.Schema

	if index.Kind == "ModuleConfig" {
		mc := ModuleConfig{}
		if err := yaml.Unmarshal(*doc, &mc); err != nil {
			return err
		}
		mcName := mc.GetName()
		if mc.Spec.Enabled == nil && mcName != "global" {
			return fmt.Errorf("Enabled field for module config %s shoud set to true or false", mcName)
		}
		if len(mc.Spec.Settings) == 0 {
			return nil
		}
		var ok bool
		schema, ok = s.moduleConfigsCache[mcName]
		if !ok {
			return fmt.Errorf("Schema for module config %s wasn't found. Check module name or use resources file for modules from sources", mc.GetName())
		}

		if mc.Spec.Version == 0 {
			return fmt.Errorf("Version field for module config %s shoud set", mcName)
		}

		var err error
		docForValidate, err = yaml.Marshal(mc.Spec.Settings)
		if err != nil {
			return fmt.Errorf("Setting for validation module config failed: %v", err)
		}
	} else {
		schema = s.getV1alpha1CompatibilitySchema(index)
	}

	if schema == nil {
		return fmt.Errorf("Schema for %s wasn't found.", index.String())
	}

	isValid, err := openAPIValidate(&docForValidate, schema)
	if !isValid {
		return fmt.Errorf("Document validation failed:\n---\n%s\n\n%w", string(*doc), err)
	}

	*doc = docForValidate

	return nil
}

func (s *SchemaStore) UploadByPath(path string) error {
	fileContent, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("Loading schema file: %v", err)
	}

	return s.upload(fileContent)
}

func (s *SchemaStore) upload(fileContent []byte) error {
	openAPISchema := new(OpenAPISchema)
	if err := yaml.UnmarshalStrict(fileContent, openAPISchema); err != nil {
		return fmt.Errorf("json unmarshal: %v", err)
	}

	for _, parsedSchema := range openAPISchema.Versions {
		schema := new(spec.Schema)

		d, err := json.Marshal(parsedSchema.Schema)
		if err != nil {
			return fmt.Errorf("expand the schema: %v", err)
		}

		if err := json.Unmarshal(d, schema); err != nil {
			return fmt.Errorf("json marshal: %v", err)
		}

		err = spec.ExpandSchema(schema, schema, nil)
		if err != nil {
			return fmt.Errorf("expand the schema: %v", err)
		}

		s.cache[SchemaIndex{Kind: openAPISchema.Kind, Version: parsedSchema.Version}] = schema
	}

	return nil
}

func openAPIValidate(dataObj *[]byte, schema *spec.Schema) (isValid bool, multiErr error) {
	validator := validate.NewSchemaValidator(schema, nil, "", strfmt.Default)

	var blank map[string]interface{}

	err := yaml.Unmarshal(*dataObj, &blank)
	if err != nil {
		return false, fmt.Errorf("openAPIValidate json unmarshal: %v", err)
	}

	result := validator.Validate(blank)
	if result.IsValid() {
		// Add default values from openAPISpec
		post.ApplyDefaults(result)
		*dataObj, _ = json.Marshal(result.Data())

		return true, nil
	}

	var allErrs *multierror.Error
	allErrs = multierror.Append(allErrs, result.Errors...)

	return false, allErrs.ErrorOrNil()
}

func ValidateDiscoveryData(config *[]byte, paths ...string) (bool, error) {
	schemaStore := NewSchemaStore(paths...)

	_, err := schemaStore.Validate(config)
	if err != nil {
		return false, fmt.Errorf("Loading schema file: %v", err)
	}

	return true, nil
}

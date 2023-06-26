- name: kubernetes.user-authz.deprecated-spec
  rules:
  - alert: UserAuthzDeprecatedCARSpecLimitNamespaces
    expr: >-
      group by (module) (d8_deprecated_car_spec_limitnamespaces) == 1
    labels:
      severity_level: "9"
    annotations:
      description: |-
        There is a cluster authorization rule with [deprecated]({{ include "helm_lib_module_uri_scheme" . }}://{{ include "helm_lib_module_public_domain" (list . "documentation") }}/modules/140-user-authz/#implementation-nuances) '.spec.limitNamespaces' parameter.
        Migrate to '.spec.namespaceSelector'.
      plk_protocol_version: "1"
      plk_markup_format: "markdown"
      plk_create_group_if_not_exists__d8_extended_monitoring_deprecated_annotation: "D8UserAuthzDeprecatedSpec,tier=cluster,prometheus=deckhouse,kubernetes=~kubernetes"
      plk_grouped_by__d8_extended_monitoring_deprecated_annotation: "D8UserAuthzDeprecatedSpec,tier=cluster,prometheus=deckhouse,kubernetes=~kubernetes"
      summary: There is a cluster authorization rule with deprecated '.spec.limitNamespaces' parameter.

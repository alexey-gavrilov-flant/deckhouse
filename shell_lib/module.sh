#!/bin/bash -e

function module::name() {
  # /deckhouse/modules/301-prometheus-metrics-adapter/hooks/superhook.sh -> prometheusMetricsAdapter
  echo $0 | sed -r 's/^\/deckhouse\/modules\/\d+-([a-zA-Z0-9-]+)\/.+/\1/' | awk -F - '{printf "%s", $1; for(i=2; i<=NF; i++) printf "%s", toupper(substr($i,1,1)) substr($i,2); print"";}'
}

function module::path() {
  # /deckhouse/modules/301-prometheus-metrics-adapter/hooks/superhook.sh -> /deckhouse/modules/301-prometheus-metrics-adapter
  echo $0 | sed -r 's/^(\/deckhouse\/modules\/\d+-[a-zA-Z0-9-]+)\/.+/\1/'
}

# $1 — target service name
function module::public_domain() {
  TEMPLATE=$(values::get --config --required global.modules.publicDomainTemplate)
  if echo "$TEMPLATE" | grep -q '%s'; then
    printf "$TEMPLATE" "$1"
  else
    echo "ERROR: global.modules.publicDomainTemplate must contain '%s'."
    return 1
  fi
}

function module::ingress_class() {
  module_name=$(module::name)
  if values::has ${module_name}.ingressClass ; then
    echo "$(values::get ${module_name}.ingressClass)"
  elif values::has global.modules.ingressClass; then
    echo "$(values::get global.modules.ingressClass)"
  else
    echo "nginx"
  fi
}

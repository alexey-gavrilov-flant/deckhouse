{{- define "rewrites" }}
rewrite ^/(.+)/modules/030-cloud-provider-openstack/usage.html$ /$1/modules/030-cloud-provider-openstack/examples.html redirect;
rewrite ^/(.+)/modules/030-cloud-provider-vsphere/usage.html$ /$1/modules/030-cloud-provider-vsphere/docs/examples.html redirect;
rewrite ^/(.+)/modules/030-cloud-provider-aws/usage.html$ /$1/modules/030-cloud-provider-aws/examples.html redirect;
rewrite ^/(.+)/modules/030-cloud-provider-azure/usage.html$ /$1/modules/030-cloud-provider-azure/examples.html redirect;
rewrite ^/(.+)/modules/030-cloud-provider-gcp/usage.html$ /$1/modules/030-cloud-provider-gcp/examples.html redirect;
rewrite ^/(.+)/modules/030-cloud-provider-yandex/usage.html$ /$1/modules/030-cloud-provider-yandex/examples.html redirect;
rewrite ^/(.+)/modules/031-local-path-provisioner/usage.html$ /$1/modules/031-local-path-provisioner/examples.html redirect;
rewrite ^/(.+)/modules/040-control-plane-manager/usage.html$ /$1/modules/040-control-plane-manager/examples.html redirect;
rewrite ^/(.+)/modules/040-node-manager/usage.html$ /$1/modules/040-node-manager/examples.html redirect;
rewrite ^/(.+)/modules/042-kube-dns/usage.html$ /$1/modules/042-kube-dns/examples.html redirect;
rewrite ^/(.+)/modules/050-network-policy-engine/usage.html$ /$1/modules/050-network-policy-engine/examples.html redirect;
rewrite ^/(.+)/modules/099-ceph-csi/usage.html$ /$1/modules/099-ceph-csi/examples.html redirect;
rewrite ^/(.+)/modules/110-istio/usage.html$ /$1/modules/110-istio/examples.html redirect;
rewrite ^/(.+)/modules/302-vertical-pod-autoscaler/usage.html$ /$1/modules/302-vertical-pod-autoscaler/examples.html redirect;
rewrite ^/(.+)/modules/303-prometheus-pushgateway/usage.html$ /$1/modules/303-prometheus-pushgateway/examples.html redirect;
rewrite ^/(.+)/modules/350-node-local-dns/usage.html$ /$1/modules/350-node-local-dns/examples.html redirect;
rewrite ^/(.+)/modules/380-metallb/usage.html$ /$1/modules/380-metallb/examples.html redirect;
rewrite ^/(.+)/modules/400-descheduler/usage.html$ /$1/modules/400-descheduler/examples.html redirect;
rewrite ^/(.+)/modules/402-ingress-nginx/usage.html$ /$1/modules/402-ingress-nginx/examples.html redirect;
rewrite ^/(.+)/modules/450-keepalived/usage.html$ /$1/modules/450-keepalived/examples.html redirect;
rewrite ^/(.+)/modules/460-log-shipper/usage.html$ /$1/modules/460-log-shipper/examples.html redirect;
rewrite ^/(.+)/modules/465-pod-reloader/usage.html$ /$1/modules/465-pod-reloader/examples.html redirect;
rewrite ^/(.+)/modules/500-basic-auth/usage.html$ /$1/modules/500-basic-auth/examples.html redirect;
rewrite ^/(.+)/modules/500-dashboard/usage.html$ /$1/modules/500-dashboard/examples.html redirect;
rewrite ^/(.+)/modules/500-okmeter/usage.html$ /$1/modules/500-okmeter/examples.html redirect;
rewrite ^/(.+)/modules/500-openvpn/usage.html$ /$1/modules/500-openvpn/examples.html redirect;
rewrite ^/(.+)/modules/500-upmeter/usage.html$ /$1/modules/500-upmeter/examples.html redirect;
rewrite ^/(.+)/modules/600-namespace-configurator/usage.html$ /$1/modules/600-namespace-configurator/examples.html redirect;
rewrite ^/(.+)/modules/810-deckhouse-web/usage.html$ /$1/modules/810-deckhouse-web/examples.html redirect;
{{- end }}

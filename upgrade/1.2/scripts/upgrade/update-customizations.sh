#!/usr/bin/env bash

set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR
set -o pipefail

usage() {
    echo >&2 "usage: ${0##*/} [-i] [CUSTOMIZATIONS-YAML]"
    exit 1
}

args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            usage
            ;;
        -i)
            inplace="yes"
            ;;
        *)
            args+=("$1")
            ;;
    esac
    shift
done

set -- "${args[@]}"

[[ $# -eq 1 ]] || usage

set -o xtrace

customizations="$1"

if [[ ! -f "$customizations" ]]; then
    echo >&2 "error: no such file: $customizations"
    usage
fi

c="$(mktemp)"
trap "rm -f '$c'" EXIT

cp "$customizations" "$c"

# Ensure Gitea's PVC configuration has been removed (stop gap for potential upgrades from CSM 0.9.4)
yq d -i "$c" 'spec.kubernetes.services.gitea.cray-service.persistentVolumeClaims'

yq w -i "$c" 'spec.kubernetes.services.cray-hms-badger-loader.nexus.repo' 'csm-diags'

yq d -i "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts(.==mma.{{ network.dns.external }})'
if [[ -z "$(yq r "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts(.==csms.{{ network.dns.external }})')" ]]; then
    yq w -i "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts[+]' 'csms.{{ network.dns.external }}'
fi

yq w -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.uai_macvlan_range_start' '{{ wlm.macvlansetup.nmn_reservation_start }}'
yq w -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.uai_macvlan_range_end' '{{ wlm.macvlansetup.nmn_reservation_end }}'
yq d -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.images'

yq w -i "$c" -- 'spec.kubernetes.services.sma-elasticsearch.esJavaOpts' '-Xmx30g -Xms30g'

yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.service.loadBalancerIP' '10.92.100.72'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.volumeClaimTemplate.storageClassName' 'sma-block-replicated'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.volumeClaimTemplate.resources.requests.storage' '16Gi'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorHmn.service.loadBalancerIP' '10.94.100.2'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.volumeClaimTemplate'

yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.service.loadBalancerIP' '10.92.100.75'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.storageClassName' 'sma-block-replicated'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.resources.requests.storage' '16Gi'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorUdpHmn.service.loadBalancerIP' '10.94.100.3'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.volumeClaimTemplate'

# Add new PowerDNS values that would be generated by CSI on a fresh install
yq w -i "$c" 'spec.network.dns.primary_server_name' primary
yq w -i --style=double "$c" 'spec.network.dns.secondary_servers' ""
yq w -i --style=double "$c" 'spec.network.dns.notify_zones' ""

# Add new generator for the PowerDNS API key Sealed Secret
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.powerdns')" ]]; then
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.name' cray-powerdns-credentials
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].type' randstr
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.name' pdns_api_key
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.length' 32
fi

# Add new generator for the dnssec key
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.dnssec')" ]]; then
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.name' dnssec-keys
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].type' static_b64
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].args.name' dummy
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].args.value' ZHVtbXkK
fi

# Remove unused cray-externaldns configuration and add domain filters required for bifurcated CAN.
yq d -i "$c" 'spec.kubernetes.services.cray-externaldns'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' 'cmn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' 'can.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' 'chn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' 'nmn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' 'hmn.{{ network.dns.external }}'

# Add required PowerDNS and Unbound configuration
yq w -i "$c" 'spec.kubernetes.services.cray-dns-unbound.domain_name' '{{ network.dns.external }}'
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.primary_server' '{{ network.dns.primary_server_name }}/{{ network.netstaticips.site_to_system_lookups }}'
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.secondary_servers' "{{ network.dns.secondary_servers }}"
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.base_domain' "{{ network.dns.external }}"
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.notify_zones' "{{ network.dns.notify_zones }}"
yq w -i "$c" 'spec.kubernetes.services.cray-powerdns-manager.cray-service.sealedSecrets[0]' '{{ kubernetes.sealed_secrets.dnssec | toYaml }}'
yq w -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.service.can.loadBalancerIP' '{{ network.netstaticips.site_to_system_lookups }}'
yq w -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.cray-service.sealedSecrets[0]' '{{ kubernetes.sealed_secrets.powerdns | toYaml }}'

if [[ "$inplace" == "yes" ]]; then
    cp "$c" "$customizations"
else
    cat "$c"
fi

ok_report
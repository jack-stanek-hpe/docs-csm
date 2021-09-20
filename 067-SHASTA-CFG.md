# Setup Site-Init From SHASTA-CFG

These procedures guide administrators through setting up the `site-init`
directory which contains important customizations for various products. The
[appendix](#appendix) is informational only; it does **not** include any
default install procedures.

* [Background](#background)
* [Create and Initialize Site-Init Directory](#create-and-initialize-site-init-directory)
* [Create Baseline System Customizations](#create-baseline-system-customizations)
* [Generate Sealed Secrets](#generate-sealed-secrets)
* [Version Control Site-Init Files](#version-control-site-init-files)
    * [Push to a Remote Repository](#push-to-a-remote-repository)
* [Customer-Specific Customizations](#customer-specific-customizations)
* [Appendix](#appendix)
    * [Tracked Sealed Secrets](#tracked-sealed-secrets)
    * [Decrypting Sealed Secrets for Review](#decrypting-sealed-secrets-for-review)


<a name="background"></a>
## Background

The `shasta-cfg` directory included in CSM includes relatively static,
installation-centric artifacts such as:

*   Cluster-wide network configuration settings required by Helm Charts
    deployed by product stream Loftsman Manifests
*   [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
*   Sealed Secret Generate Blocks -- an form of plain-text input that renders
    to a Sealed Secret
*   Helm Chart value overrides that are merged into Loftsman Manifests by
    product stream installers

<a name="create-and-initialize-site-init-directory"></a>
## Create and Initialize Site-Init Directory

1.  Create directory `/mnt/pitdata/prep/site-init`:
    
    ```bash
    linux# mkdir -p /mnt/pitdata/prep/site-init
    linux# cd /mnt/pitdata/prep/site-init
    ```

1.  Initialize `/mnt/pitdata/prep/site-init` from CSM:
    
    ```bash
    linux# /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/meta/init.sh /mnt/pitdata/prep/site-init
    ```

1.  The `yq` tool used in the following procedures is available under
`/mnt/pitdata/prep/site-init/utils/bin` once the SHASTA-CFG repo has been
cloned
    
    ```bash
    linux# alias yq="/mnt/pitdata/${CSM_RELEASE}/shasta-cfg/utils/bin/$(uname | awk '{print tolower($0)}')/yq"
    ```

<a name="create-baseline-system-customizations"></a>
## Create Baseline System Customizations

The following steps update `/mnt/pitdata/prep/site-init/customizations.yaml`
with system-specific customizations.

1.  Ensure system-specific settings generated by CSI are merged into
    `customizations.yaml`:
    
    > Note the system name environment variable `SYSTEM_NAME` must be set 
    
    ```bash
    linux# yq merge -xP -i /mnt/pitdata/prep/site-init/customizations.yaml <(yq prefix -P "/mnt/pitdata/prep/${SYSTEM_NAME}/customizations.yaml" spec)
    ```
    
1. Set the cluster name:
    
    ```bash
    linux# yq write -i /mnt/pitdata/prep/site-init/customizations.yaml spec.wlm.cluster_name "$SYSTEM_NAME"
    ```

1. Make a backup copy of `/mnt/pitdata/prep/site-init/customizations.yaml`:
    
    ```bash
    linux# cp /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/customizations.yaml.prepassword
    ```
    
1.  Review the configuration to generate these sealed secrets in `customizations.yaml` in the `site-init` directory:
    
    * `spec.kubernetes.sealed_secrets.cray_reds_credentials`
    * `spec.kubernetes.sealed_secrets.cray_meds_credentials`
    * `spec.kubernetes.sealed_secrets.cray_hms_rts_credentials`
    
    Edit `customizations.yaml`, replacing the `Password` references with values appropriate for your system. See 
    [Decrypting Sealed Secrets for Review](#decrypting-sealed-secrets-for-review) if you need to examine
    credentials from prior installs.
    
1. Review the changes that you made:
    
    ```bash
    linux# diff /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/customizations.yaml.prepassword
    ```
    
1. Validate that REDS/MEDS/RTS sealed secrets contain valid JSON using `jq`:
    
    ```bash
    # Validate REDS credentials (used by the REDS and HMS discovery services, 
    # targeting River Redfish BMC endpoints and management switches)
    
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray_reds_credentials.generate.data[0].args.value' | jq
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray_reds_credentials.generate.data[1].args.value' | jq
    
    # NOTE: For vault_redfish_defaults, the only entry used is '{"Cray": {"Username": "root", "Password": "XXXX"}'
    # Make sure it is specified as shown, with the 'Cray' key. This key is not
    # used in any of the other credential specifications. Make sure Username and
    # Password entries are correct.
    
    # Validate MEDS credentials (used by the MEDS service, targeting 
    # Redfish BMC endpoints). Make sure Username and Password entries are correct.
    
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray_meds_credentials.generate.data[0].args.value' | jq
    
    # Validate RTS credentials (used by the Redfish Translation Service, targeting
    # River Redfish BMC endpoints and PDU controllers). Make sure Username and 
    # Password entries are correct.
    
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray_hms_rts_credentials.generate.data[0].args.value' | jq
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray_hms_rts_credentials.generate.data[1].args.value' | jq
    ```
    
1.  To customize the PKI Certificate Authority (CA) used by the platform, see
    [Customizing the Platform CA](055-CERTIFICATE-AUTHORITY.md). 

    > **`IMPORTANT`** The CA may not be modified after install.

1.  To federate Keycloak with an upstream LDAP:

    > **`INTERNAL ONLY`** On internal HPE systems, if the IP address for
    > the ncn-m001 node is even then use `ldaps://dcldap2.us.cray.com`,
    > otherwise use `ldaps://dcldap3.us.cray.com`. For example, `ping
    > fanta-ncn-m001.us.cray.com` shows the IP address is `172.30.52.72`,
    > so fanta would use `ldaps://dcldap2.us.cray.com` as the
    > `ldap_connection_url`. This just spreads the load over the two LDAP
    > replicas.
    >
    > ```bash
    > linux# export LDAP=dcldap2.us.cray.com
    > ```

    *   If LDAP requires TLS (recommended), update the `cray-keycloak` sealed
        secret value by supplying a base64 encoded Java KeyStore (JKS) that
        contains the CA certificate that signed the LDAP server's host key. The
        password for the JKS file must be `password`. Admins may use the
        `keytool` command from the `openjdk:11-jre-slim` container image
        packaged with CSM to create a JKS file that includes a PEM-encoded
        CA certificate to verify the LDAP host(s) as follows:

        Load the `openjdk` container image:

        > **`NOTE`** Requires a properly configured Docker or Podman
        > environment.

        ```bash
        linux# /mnt/pitdata/${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/library/openjdk:11-jre-slim
        ```

        Create (or update) `cert.jks` with the PEM-encoded CA certificate for an
        LDAP host:

        > **`IMPORTANT`** Replace `<ca-cert.pem>` and `<alias>` as appropriate.

        ```bash
        linux# podman run --rm -v "$(pwd):/data" dtr.dev.cray.com/library/openjdk:11-jre-slim keytool \
                      -importcert -trustcacerts -file /data/<ca-cert.pem> -alias <alias> \
                      -keystore /data/certs.jks -storepass password -noprompt
        ```

        > **`INTERNAL ONLY`** For example, on internal HPE systems, create the
        > `certs.jks.b64` file as follows:
        > 
        > *   Get the issuer certificate for dcldap. Use `openssl s_client` to connect
        >     and show the certificate chain returned by the LDAP host:
        > 
        >     ```bash
        >     linux# openssl s_client -showcerts -connect $LDAP:636 </dev/null
        >     ```
        > 
        >     Either manually extract (i.e., cut/paste) the issuer's
        >     certificate into `cacert.pem` or try the following commands to
        >     create it automatically.
        > 
        >     > **`NOTE`** The following commands were verified using OpenSSL
        >     > version 1.1.1d and use the `-nameopt RFC2253` option to ensure
        >     > consistent formatting of distinguished names (DNs).
        >     > Unfortunately, older versions of OpenSSL may not support
        >     > `-nameopt` on the `s_client` command or may use a different
        >     > default format. As a result, your mileage may vary; however,
        >     > you should be able to manually extract the issuer certificate
        >     > from the output of the above `openssl s_client` example if the
        >     > following commands are unsuccessful.
        > 
        >     1.  Observe the issuer's DN:
        > 
        >         ```bash
        >         linux# openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:636 </dev/null 2>/dev/null | grep issuer= | sed -e 's/^issuer=//'
        >         ```
        >
        >         Expected output looks like:
        >
        >         ```
        >         emailAddress=dcops@hpe.com,CN=Data Center,OU=HPC/MCS,O=HPE,ST=WI,C=US
        >         ```
        > 
        >     2.  Extract the issuer's certificate using `awk`:
        > 
        >         > **`NOTE`** The issuer DN is properly escaped as part of the
        >         > `awk` pattern below. If the value you are using is
        >         > different, be sure to escape it properly!
        > 
        >         ```bash
        >         linux# openssl s_client -showcerts -nameopt RFC2253 -connect $LDAP:636 </dev/null 2>/dev/null | 
        >                   awk '/s:emailAddress=dcops@hpe.com,CN=Data Center,OU=HPC\/MCS,O=HPE,ST=WI,C=US/,/END CERTIFICATE/' | 
        >                   awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > cacert.pem
        >         ```
        > 
        > *   Verify issuer's certificate was properly extracted and saved in `cacert.pem`:
        > 
        >     ```bash
        >     linux# cat cacert.pem
        >     ```
        >
        >     Expected output looks like:
        >
        >     ```
        >     -----BEGIN CERTIFICATE-----
        >     MIIDvTCCAqWgAwIBAgIUYxrG/PrMcmIzDuJ+U1Gh8hpsU8cwDQYJKoZIhvcNAQEL
        >     BQAwbjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldJMQwwCgYDVQQKDANIUEUxEDAO
        >     BgNVBAsMB0hQQy9NQ1MxFDASBgNVBAMMC0RhdGEgQ2VudGVyMRwwGgYJKoZIhvcN
        >     AQkBFg1kY29wc0BocGUuY29tMB4XDTIwMTEyNDIwMzM0MVoXDTMwMTEyMjIwMzM0
        >     MVowbjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldJMQwwCgYDVQQKDANIUEUxEDAO
        >     BgNVBAsMB0hQQy9NQ1MxFDASBgNVBAMMC0RhdGEgQ2VudGVyMRwwGgYJKoZIhvcN
        >     AQkBFg1kY29wc0BocGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
        >     AQEAuBIZkKitHHVQHymtaQt4D8ZhG4qNJ0cTsLhODPMtVtBjPZp59e+PWzbc9Rj5
        >     +wfjLGteK6/fNJsJctWlS/ar4jw/xBIPMk5pg0dnkMT2s7lkSCmyd9Uib7u6y6E8
        >     yeGoGcb7I+4ZI+E3FQV7zPact6b17xmajNyKrzhBGEjYucYJUL5iTgZ6a7HOZU2O
        >     aQSXe7ctiHBxe7p7RhHCuKRrqJnxoohakloKwgHHzDLFQzX/5ADp1hdJcduWpaXY
        >     RMBu6b1mhmwo5vmc+fDnfUpl5/X4i109r9VN7JC7DQ5+JX8u9SHDGLggBWkrhpvl
        >     bNXMVCnwnSFfb/rnmGO7rdJSpwIDAQABo1MwUTAdBgNVHQ4EFgQUVg3VYExUAdn2
        >     WE3e8Xc8HONy/+4wHwYDVR0jBBgwFoAUVg3VYExUAdn2WE3e8Xc8HONy/+4wDwYD
        >     VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAWLDQLB6rrmK+gwUY+4B7
        >     0USbQK0JkLWuc0tCfjTxNQTzFb75PeH+GH21QsjUI8VC6QOAAJ4uzIEV85VpOQPp
        >     qjz+LI/Ej1xXfz5ostZQu9rCMnPtVu7JT0B+NV7HvgqidTfa2M2dw9yUYS2surZO
        >     8S0Dq3Bi6IEhtGU3T8ZpbAmAp+nNsaJWdUNjD4ECO5rAkyA/Vu+WyMz6F3ZDBmRr
        >     ipWM1B16vx8rSpQpygY+FNX4e1RqslKhoyuzXfUGzyXux5yhs/ufOaqORCw3rJIx
        >     v4sTWGsSBLXDsFM3lBgljSAHfmDuKdO+Qv7EqGzCRMpgSciZihnbQoRrPZkOHUxr
        >     NA==
        >     -----END CERTIFICATE-----
        >     ```
        > 
        > *   Create `certs.jks`:
        > 
        >     ```bash
        >     linux# podman run --rm -v "$(pwd):/data" dtr.dev.cray.com/library/openjdk:11-jre-slim keytool -importcert \
        >                   -trustcacerts -file /data/cacert.pem -alias cray-data-center-ca -keystore /data/certs.jks \
        >                   -storepass password -noprompt
        >     ```

        Create `certs.jks.b64` by base-64 encoding `certs.jks`:

        ```bash
        linux# base64 certs.jks > certs.jks.b64
        ```

        Then, inject and encrypt `certs.jks.b64` into `customizations.yaml`:

        ```bash
        linux# cat <<EOF | yq w - 'data."certs.jks"' "$(<certs.jks.b64)" | \
            yq r -j - | /mnt/pitdata/prep/site-init/utils/secrets-encrypt.sh | \
            yq w -f - -i /mnt/pitdata/prep/site-init/customizations.yaml 'spec.kubernetes.sealed_secrets.cray-keycloak'
        {
          "kind": "Secret",
          "apiVersion": "v1",
          "metadata": {
            "name": "keycloak-certs",
            "namespace": "services",
            "creationTimestamp": null
          },
          "data": {}
        }
        EOF
        ```

    *   Update the `keycloak_users_localize` sealed secret with the
        appropriate value for `ldap_connection_url`.

        Set `ldap_connection_url` in `customizations.yaml`:

        > **`IMPORTANT`** Replace `<ldap-url>` as appropriate.

        ```bash
        linux# yq write -i /mnt/pitdata/prep/site-init/customizations.yaml \
                'spec.kubernetes.sealed_secrets.keycloak_users_localize.generate.data.(args.name==ldap_connection_url).args.value' '<ldap-url>'
        ```

        > **`INTERNAL ONLY`** 
        > 
        > Set `ldap_connection_url` in `customizations.yaml`:
        > 
        > ```bash
        > linux# yq write -i /mnt/pitdata/prep/site-init/customizations.yaml \
        >         'spec.kubernetes.sealed_secrets.keycloak_users_localize.generate.data.(args.name==ldap_connection_url).args.value' "ldaps://$LDAP"
        > ```
        > 
        > On success, review the `keycloak_users_localize` sealed secret:
        > 
        > ```bash
        > linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.sealed_secrets.keycloak_users_localize
        > ```
        > 
        > Expected output is similar to:
        >
        > ```
        > generate:
        >     name: keycloak-users-localize
        >     data:
        >     - type: static
        >         args:
        >         name: ldap_connection_url
        >         value: ldaps://dcldap2.us.cray.com
        > ```

    *   Configure the `ldapSearchBase` and `localRoleAssignments` settings for
        the `cray-keycloak-users-localize` chart in `customizations.yaml`.

        Set `ldapSearchBase` in `customizations.yaml`:

        > **`IMPORTANT`** Replace `<search-base>` as appropriate.

        ```bash
        linux# yq write -i /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.services.cray-keycloak-users-localize.ldapSearchBase '<search-base>'
        ```

        Set `localRoleAssignments` that map to `admin` and/or `user` roles for
        both `shasta` and `cray` clients in `customizations.yaml`:

        > **`IMPORTANT`** Replace `<admin-group>` and `<user-group>` as
        > appropriate. Also add other assignments as desired.

        ```bash
        linux# yq write -s - -i /mnt/pitdata/prep/site-init/customizations.yaml <<EOF
        - command: update
          path: spec.kubernetes.services.cray-keycloak-users-localize.localRoleAssignments
          value:
          - {"group": "<admin-group>", "role": "admin", "client": "shasta"}
          - {"group": "<admin-group>", "role": "admin", "client": "cray"}
          - {"group": "<user-group>", "role": "user", "client": "shasta"}
          - {"group": "<user-group>", "role": "user", "client": "cray"}
        EOF
        ```

        > **`INTERNAL ONLY`** For example, on internal HPE systems appropriate
        > settings are:
        > 
        > ```yaml
        > ldapSearchBase: "dc=dcldap,dc=dit"
        > localRoleAssignments:
        >     - {"group": "criemp", "role": "admin", "client": "shasta"}
        >     - {"group": "criemp", "role": "admin", "client": "cray"}
        >     - {"group": "craydev", "role": "admin", "client": "shasta"}
        >     - {"group": "craydev", "role": "admin", "client": "cray"}
        >     - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
        >     - {"group": "shasta_admins", "role": "admin", "client": "cray"}
        >     - {"group": "shasta_users", "role": "user", "client": "shasta"}
        >     - {"group": "shasta_users", "role": "user", "client": "cray"}
        > ```
        > 
        > Set `ldapSearchBase` in `customizations.yaml`:
        > 
        > ```bash
        > linux# yq write -i /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.services.cray-keycloak-users-localize.ldapSearchBase 'dc=dcldap,dc=dit'
        > ```
        > 
        > Set `localRoleAssignments` in `customizations.yaml`:
        > 
        > ```bash
        > linux# yq write -s - -i /mnt/pitdata/prep/site-init/customizations.yaml <<EOF
        > - command: update
        >   path: spec.kubernetes.services.cray-keycloak-users-localize.localRoleAssignments
        >   value:
        >   - {"group": "criemp", "role": "admin", "client": "shasta"}
        >   - {"group": "criemp", "role": "admin", "client": "cray"}
        >   - {"group": "craydev", "role": "admin", "client": "shasta"}
        >   - {"group": "craydev", "role": "admin", "client": "cray"}
        >   - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
        >   - {"group": "shasta_admins", "role": "admin", "client": "cray"}
        >   - {"group": "shasta_users", "role": "user", "client": "shasta"}
        >   - {"group": "shasta_users", "role": "user", "client": "cray"}
        > EOF
        > ```
        > 
        > On success, review the `cray-keycloak-users-localize` values:
        > 
        > ```bash
        > linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.services.cray-keycloak-users-localize
        > ```
        >
        > Expected output looks similar to:
        >
        > ```
        > sealedSecrets:
        >     - '{{ kubernetes.sealed_secrets.keycloak_users_localize | toYaml }}'
        > localRoleAssignments:
        >     - {"group": "criemp", "role": "admin", "client": "shasta"}
        >     - {"group": "criemp", "role": "admin", "client": "cray"}
        >     - {"group": "craydev", "role": "admin", "client": "shasta"}
        >     - {"group": "craydev", "role": "admin", "client": "cray"}
        >     - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
        >     - {"group": "shasta_admins", "role": "admin", "client": "cray"}
        >     - {"group": "shasta_users", "role": "user", "client": "shasta"}
        >     - {"group": "shasta_users", "role": "user", "client": "cray"}
        > ldapSearchBase: dc=dcldap,dc=dit
        > ```

1.  If you need to resolve outside hostnames, you will need to configure
    forwarding in the cray-dns-unbound service. For example, if you are using a
    hostname and not an IP for the upstream LDAP server in step 4 above, you
    will need to be able to resolve that hostname.

    Set the `localZones` and `forwardZones` for the `cray-dns-unbound` service:

    ```bash
    linux# yq write -s - -i /mnt/pitdata/prep/site-init/customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-dns-unbound
      value:
        localZones:
        - localType: static
          name: "local"
        forwardZones:
        - name: "."
          forwardIps:
          - "{{ network.netstaticips.system_to_site_lookups }}"
    EOF
    ```

    On success, review the `cray-dns-unbound` values.
    
    ```bash
    linux# yq read /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.services.cray-dns-unbound
    ```
    
    Expected output looks similar to:
    
    ```
    localZones:
    - localType: static
      name: "local"
    forwardZones:
    - name: "."
      forwardIps:
      - "{{ network.netstaticips.system_to_site_lookups }}"
    ```

1.  Review `customizations.yaml` in the `site-init` directory and replace remaining `~FIXME~` values with
    appropriate settings.
    
    1. Create backup copy of `customizations.yaml`:
        
        ```bash
        linux# cp /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/customizations.yaml-prefixme
        ```
    
    1. Edit `customizations.yaml`
        For the following `~FIXME~` values, use the example provided and just remove the `~FIXME~ e.g.`
        
        ```
           sma-rsyslog-aggregator:
             cray-service:
               service:
                 loadBalancerIP: ~FIXME~ e.g. 10.92.100.72
             rsyslogAggregatorHmn:
               service:
                 loadBalancerIP: ~FIXME~ e.g. 10.94.100.2
        
           sma-rsyslog-aggregator-udp:
             cray-service:
               service:
                 loadBalancerIP: ~FIXME~ e.g. 10.92.100.75
             rsyslogAggregatorUdpHmn:
               service:
                 loadBalancerIP: ~FIXME~ e.g. 10.94.100.3
        ```
    
    1. Review your changes:
        ```bash
        linux# diff /mnt/pitdata/prep/site-init/customizations.yaml /mnt/pitdata/prep/site-init/customizations.yaml-prefixme
        ```


<a name="generate-sealed-secrets"></a>
## Generate Sealed Secrets

Secrets are stored in `customizations.yaml` as `SealedSecret` resources (i.e.,
encrypted secrets) which are deployed by specific charts and decrypted by the
Sealed Secrets operator. But first, those secrets must be seeded generated and
encrypted.

1.  Load the `zeromq` container image required by Sealed Secret Generators:

    > **`NOTE`** Requires a properly configured Docker or Podman environment.

    ```bash
    linux# /mnt/pitdata/${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/zeromq/zeromq:v4.0.5
    ```

1.  Re-encrypt existing secrets:

    ```bash
    linux# /mnt/pitdata/prep/site-init/utils/secrets-reencrypt.sh /mnt/pitdata/prep/site-init/customizations.yaml \
                /mnt/pitdata/prep/site-init/certs/sealed_secrets.key /mnt/pitdata/prep/site-init/certs/sealed_secrets.crt
    ```

1.  Generate secrets:

    ```bash
    linux# /mnt/pitdata/prep/site-init/utils/secrets-seed-customizations.sh /mnt/pitdata/prep/site-init/customizations.yaml
    ```
    
    Expected output looks similar to:
    
    ```
    Creating Sealed Secret keycloak-certs
    Generating type static_b64...
    Creating Sealed Secret keycloak-master-admin-auth
    Generating type static...
    Generating type static...
    Generating type randstr...
    Generating type static...
    Creating Sealed Secret cray_reds_credentials
    Generating type static...
    Generating type static...
    Creating Sealed Secret cray_meds_credentials
    Generating type static...
    Creating Sealed Secret cray_hms_rts_credentials
    Generating type static...
    Generating type static...
    Creating Sealed Secret vcs-user-credentials
    Generating type randstr...
    Generating type static...
    Creating Sealed Secret generated-platform-ca-1
    Generating type platform_ca...
    Creating Sealed Secret pals-config
    Generating type zmq_curve...
    Generating type zmq_curve...
    Creating Sealed Secret munge-secret
    Generating type randstr...
    Creating Sealed Secret slurmdb-secret
    Generating type static...
    Generating type static...
    Generating type randstr...
    Generating type randstr...
    Creating Sealed Secret keycloak-users-localize
    Generating type static...
    ```


<a name="version-control-site-init-files"></a>
## Version Control Site-Init Files

Setup `/mnt/pitdata/prep/site-init` as a Git repository in order to manage the
baseline configuration during initial system installation.

1.  Initialize `/mnt/pitdata/prep/site-info` as a Git repository:

    ```bash
    linux# cd /mnt/pitdata/prep/site-init
    linux# git init .
    ```

1.  (Optional) **`WARNING`** If production system or operational security is a
    concern, do NOT store the sealed secret private key in Git; instead,
    **store the sealed secret key outside of Git in a secure offline system**.
    To ensure these sensitive keys are not accidentally committed, configure
    `.gitignore` to ignore files under the `certs` directory:

    ```bash
    linux# echo "certs/" >> .gitignore
    ```

1.  Stage site-init files to be committed:

    ```bash
    linux# git add -A
    ```

1.  Review what will be committed:

    ```bash
    linux# git status
    ```

1.  Commit all the above changes as the baseline configuration:

    ```bash
    linux# git commit -m "Baseline configuration for $(/mnt/pitdata/${CSM_RELEASE}/lib/version.sh)"
    ```


<a name="push-to-a-remote-repository"></a>
### Push to a Remote Repository

It is **strongly recommended** to that the site-init repository be maintained
off-cluster. Add a remote repository and push the baseline configuration on
`master` branch to a corresponding remote branch. 


<a name="customer-specific-customizations"></a>
## Customer-Specific Customizations

Customer-specific customizations are any changes on top of the baseline
configuration to satisfy customer-specific requirements. It is recommended that
customer-specific customizations be tracked on branches separate from the
mainline in order to make them easier to manage.

Apply any customer-specific customizations by merging the corresponding
branches into `master` branch of `/mnt/pitdata/prep/site-init`.

When considering merges, and especially when resolving conflicts, carefully
examine differences to ensure all changes are relevant. For example, when
applying a customer-specific customization used in a prior version, be sure the
change still makes sense. It is common for options to change as new features are
introduced and bugs are fixed.


----


<a name="appendix"></a>
## Appendix


<a name="tracked-sealed-secrets"></a>
## Tracked Sealed Secrets

Tracked sealed secrets are regenerated every time secrets are seeded (see the
use of `utils/secrets-seed-customizations.sh` above). View currently tracked
sealed secrets via:

```bash
linux# yq read /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets
```

Expected output looks similar to:

```
- cray_reds_credentials
- cray_meds_credentials
- cray_hms_rts_credentials
```

In order to prevent tracked sealed secrets from being regenerated, they **MUST
BE REMOVED** from the `spec.kubernetes.tracked_sealed_secrets` list in
`/mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml` prior to [seeding](#generate-sealed-secrets).
To retain the REDS/MEDS/RTS credentials, run:

```bash
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
```

<a name="decrypting-sealed-secrets-for-review"></a>
## Decrypting Sealed Secrets for Review

For administrators that would like to decrypt and review previously encrypted
sealed secrets, you can use the `secrets-decrypt.sh` utility in SHASTA-CFG.

Syntax: `secret-decrypt.sh SEALED-SECRET-NAME SEALED-SECRET-PRIVATE-KEY CUSTOMIZATIONS-YAML`

```bash
linux:/mnt/pitdata/prep/site-init# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults | sed -e 's/"//g' | base64 -d; echo
```

Expected output looks similar to:

```
{"Username": "root", "Password": "..."}
```
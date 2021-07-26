## Retrieve an Authentication Token

Retrieve a token for authenticating to the API gateway.

The following are important properties of authentication tokens:
-   Keycloak access tokens remain valid for 365 days
-   Secrets do not expire; they are persistent in Keycloak
-   Tokens and/or secrets can be revoked at anytime by an admin

The API gateway uses OAuth2 for authentication. A token is required to authenticate with this gateway.

### Procedure

1.  Retrieve a token.

    Retrieving a token depends on whether the request is based on a regular user \(as defined directly in Keycloak or backed by LDAP\) or a service account.

    -   **Resource owner password grant \(user account\)** - In this case, the user account flow requires the username, password, and the client ID.

        In the example below, replace `myuser`, `mypass`, and `shasta` in the cURL command with site-specific values. The `shasta` client is created during the SMS install process.

        In the following example, the python -mjson.tool is not required, it is simply used to format the output for readability.

        ```bash
        ncn-w001# curl -s \
         -d grant_type=password \
         -d client_id=shasta \
         -d username=myuser \
         -d password=mypass \
         https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
         python -mjson.tool
        ```

        Expected output:

        ```bash
        {
            "access_token": "ey...IA", <<-- Note this value
            "expires_in": 300,
            "not-before-policy": 0,
            "refresh_expires_in": 1800,
            "refresh_token": "ey...qg",
            "scope": "profile email",
            "session_state": "10c7d2f7-8921-4652-ad1e-10138ec6fbc3",
            "token_type": "bearer"
        }
        ```

        Use the value of `access_token` to make requests.

    -   **Client credentials \(service account\)** - The client credentials flow requires a client ID and client secret.

        There are a couple of ways to use a service account:

        -   By creating a new service account.
        -   By using the Keycloak client that was generated by the System Management Services \(SMS\) installation process. The client ID is `admin-client`. The client secret is generated during the install and put into a Kubernetes secret named `admin-client-auth`. Retrieve the client secret from this secret as follows:

            ```bash
            ncn-w001# echo "$(kubectl get secrets admin-client-auth \
            -ojsonpath='{.data.client-secret}' | base64 -d)"
            2b0d6df0-183b-40e6-93be-51c7854388a1
            ```

        -   Given the client ID and secret, the user can retrieve a token by requesting one from Keycloak. In the example below, replace the string being assigned to client\_secret with the actual client secret from the previous step.

            In the following example, the python -mjson.tool is not required, it formats the output for readability.

            ```bash
            ncn-w001# curl -s \
             -d grant_type=client_credentials \
             -d client_id=admin-client \
             -d client_secret=2b0d6df0-183b-40e6-93be-51c7854388a1 \
             https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token |
             python -mjson.tool
            ```

            Expected output:

            ```bash
            {
                "access_token": "ey...DA", <<-- Note this value
                "expires_in": 300,
                "not-before-policy": 0,
                "refresh_expires_in": 1800,
                "refresh_token": "ey...kg",
                "scope": "profile email",
                "session_state": "ca8ab15c-2378-40c1-8063-7a522274fce0",
                "token_type": "bearer"
            }
            ```

            Use the value of `access_token` to make requests.

2.  Present the token.

    To present the access token on the request, put it in the `Authorization` header on the request as a `Bearer` token.

    For example:

    ```bash
    ncn-w001# TOKEN=access_token
    ncn-w001# curl -H "Authorization: Bearer $TOKEN" \
    https://api-gw-service-nmn.local/apis/capmc/capmc/get_node_rules
    {
        "e":0,
        "err_msg":"",
        "latency_node_off":60,
        "latency_node_on":120,
        "latency_node_reinit":180,
        "max_off_req_count":-1,
        "max_off_time":-1,
        "max_on_req_count":-1,
        "max_reinit_req_count":-1,
        "min_off_time":-1
    }
    ```



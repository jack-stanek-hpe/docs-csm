# Apply CSM Configuration to NCNs

NCN personalization uses the Configuration Framework Service (CFS) to apply
post-boot configuration to the HPE Cray EX management nodes.  This guide
focuses on CSM configuration only, although additional software product streams
may also require NCN personalization.

The CSM configuration content sets up passwordless ssh, and as such, this applying it is optional.
Local site security requirements may preclude use of passwordless SSH access between products or
environments. Applying this configuration allows basic passwordless SSH to function for the lifetime
of the affected file system.

For more information on the steps that follow, see
[Manage a Configuration with CFS](Manage_a_Configuration_with_CFS.md)

**NOTE:** If this is your first time applying CSM configuration to NCNs, it is recommended that you read the
rest of this guide, as this sets up passwordless ssh, which may not be desirable in all environments or
with the defaults provided.  If the defaults are desired, skip to [Deploying CSM Configuration](#Deploying CSM Configuration)

## Passwordless SSH Setup

Passwordless SSH key pairs for the Cray System Management (CSM) are created automatically and periodically
maintained with a Kubernetes deployment. Administrators can use these provided keys, provide their own keys, 
or use their own solution for authentication. Master, worker, or storage nodes (NCNs) must have these keys 
applied to them through the Configuration Framework Service (CFS) in order for passwordless SSH to work.

For more information on this topic, see
[Passwordless SSH](Manage_a_Configuration_with_CFS.md#Passwordless SSH)

### Replacing SSH Keys

Administrators that wish to provide their own keys can use the provided `replace_ssh_keys.sh` script.
This will replace the ssh keypair stored in Kubernetes with keys of the administrators choosing.
**NOTE:**: This will not replace keys that have already been deployed.

```bash
ncn-m001# /opt/cray/csm/scripts/configuration/passwordless_ssh/replace_ssh_keys.sh \
--public-key-file ./id_rsa.pub --private-key-file ./id_rsa
```

For more information on this step or to debug, see
[Provide Custom Keys](Manage_a_Configuration_with_CFS.md#Provide Custom Keys)

### Restoring SSH Keys

To restore the provided ssh key-pair, administrators can use the provided `restore_ssh_keys.sh` script.
**NOTE:**: This will not replace keys that have already been deployed.

```bash
ncn-m001# /opt/cray/csm/scripts/configuration/passwordless_ssh/restore_ssh_keys.sh
```

For more information on this step or to debug, see
[Restore Keys to Initial Defaults](Manage_a_Configuration_with_CFS.md#Restore Keys to Initial Defaults)

<a name="set_root_password"></a>
## Root Password Setup

CSM configuration also updates the root password, which read from Vault using the
`secret/csm/management_nodes` secret and the `root_password` key in that secret.
To set the password in Vault, follow steps 1-3 in the
[Update NCN Passwords](../../operations/security_and_authentication/Update_NCN_Passwords.md)
procedure.

To only change the root password, use the
`rotate-pw-mgmt-nodes.yml` playbook by following the instructions in the
[Update NCN Passwords](../../operations/security_and_authentication/Update_NCN_Passwords.md)
procedure.

## Deploying CSM Configuration

Once the ssh keys have been set in Kubernetes, they can be deployed using the `apply_csm_configuration.sh`
script, which will create the necessary CFS configuration, set the desired configuration on all NCNs,
and monitor until CFS has completed.

```bash
ncn-m001# /opt/cray/csm/scripts/configuration/passwordless_ssh/apply_csm_configuration.sh
```

### Deployment Steps
 
By default the script will perform the following steps:
1. Finds the latest installed release version of the CSM product stream.
1. Finds the latest commit on the release branch of the `csm-config-management` repo.
1. Creates or updates the `ncn-personalization.json` configuration file.
1. Finds all nodes in HSM without the `Compute` role.
1. Disables configuration for all NCN nodes.
1. Updates the `ncn-personalization` configuration in CFS from the `ncn-personalization.json` file.
1. Enables configuration for all NCN nodes, and sets their desired configuration to `ncn-personalization`.
1. Monitors CFS until all NCN nodes have successfully completed, or failed, configuration.

### Deployment Overrides

The script also supports several flags to override these behaviors:
- csm-release: Overrides the version of the CSM release that is used.  Defaults to the latest version.
- git-commit: Overrides the git commit cloned for the configuration content.  Defaults to the latest
commit on the csm-release branch.
- git-clone-url: Overrides the source of the configuration content.  Defaults to `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git`
- ncn-config-file: Sets a file other than `ncn-personalization.json` to be used for the configuration.
- xnames: A comma separated list xnames to deploy to.  Defaults to all non-compute nodes in HSM.
- clear-state: Clears existing state from components to ensure CFS runs.  This can be used if
configuration needs to be re-run on successful nodes with no change to the git content since the previous
run.  E.g. if the ssh keys have changed. 

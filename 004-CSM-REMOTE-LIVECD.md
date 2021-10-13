# LiveCD Remote ISO Install

This page will assist you with configuring and activating your booted LiveCD through a remote KVM.

* [LiveCD Setup](#livecd-setup)
    * [LiveCD Interfaces](#livecd-interfaces)
    * [Setup the Site-Link Connection(s)](#setup-site-link-connections)
    * [Setup Internal Connections](#setup-internal-connections)
* [Customization](#customization)
    * [Hostname](#hostname)
    * [SHASTA-CFG](#shasta-cfg)
    * [Cray Site Init](#cray-site-init)
    * [CA Certificate](#ca-certificate)
* [Validate the LiveCD platform.](#validate-the-livecd-platform)
  * [LiveCD Services](#livecd-services)
  * [Configure NTP](#configure-ntp)
  * [Validate the LiveCD Services](#validate-the-livecd-services)
  * [Verify Outside Name Resolution](#verify-outside-name-resolution)
    
Attaching the ISO to the node varies by the vendor:
- [HPE uses iLO](062-LIVECD-VIRTUAL-ISO-BOOT.md#hpe-ilo-bmcs)
- [Gigabyte](062-LIVECD-VIRTUAL-ISO-BOOT.md#gigabyte-bmcs)
- [Intel](062-LIVECD-VIRTUAL-ISO-BOOT.md#intel-bmcs)

For information on how-to remote attach an ISO, see [LiveCD ISO Boot](062-LIVECD-VIRTUAL-ISO-BOOT.md).

<a name="livecd-setup"></a>
## LiveCD Setup

<a name="livecd-interfaces"></a>
### LiveCD Interfaces

> Set up variables for lan0 configuration

```bash
pit# site_ip=172.30.XXX.YYY/20
pit# site_gw=172.30.48.1
pit# site_dns=172.30.84.40
pit# site_nic=p1p2
```

- `site_nic` The interface that is directly attached to the site network on ncn-m001. This should not be lan0.
- `site_ip` The IP address and netmask in CIDR notation that is assigned to the site connection on ncn-m001. NOTE:  This is NOT just the network, but also the IP address.
- `site_gw` The gateway address for the site network. This will be used to set up the default gateway route on ncn-m001.
- `site_dns` ONE of the site DNS servers. The script does not currently handle setting more than one IP address here.

<a name="setup-site-link-connections"></a>
#### Setup Site-Link Connection(s)

External, direct access.

> **`PREFERRED`** use the generated files from your system inputs...
```bash
pit# system_name=bigbird
pit# cp /var/www/ephemeral/prep/${system_name}/cpt-files/ /etc/sysconfig/network/
pit# wicked ifreload lan0
pit# /root/bin/csi-set-hostname.sh
```

> **`MANUAL`** without CPT files generated by CSI...
```bash
pit# /root/bin/csi-setup-lan0.sh $site_ip $site_gw $site_dns $site_nic
pit# /root/bin/csi-set-hostname.sh
```

If there is an IP showing for `ip a s lan0` then you could exit your CONSOLE and return with an SSH connection (if you prefer).

<a name="setup-internal-connections"></a>
#### Setup Internal Connections

Now reload the other configurations:

> **`PREFERRED`** use the generated files from your system inputs:

```bash
pit# wicked ifreload all
```

> **`MANUAL`** without CPT files generated by CSI:
> **`NOTE`**: Be sure to set the `nmn_cidr`, `hmn_cidr`, and `can_cidr` variables first.
```bash
pit# /root/bin/csi-setup-vlan002.sh $nmn_cidr
pit# /root/bin/csi-setup-vlan004.sh $hmn_cidr
pit# /root/bin/csi-setup-vlan007.sh $can_cidr
```

<a name="customization"></a>
## Customization

<a name="hostname"></a>
### Hostname

To prevent mistakes, naming the LiveCD can be a useful visual aide.

> **`NOTE`** do not confuse other administrators by neglecting the "-pit" suffix.

Set the hostname with `hostnamectl`:
```bash
pit# hostnamectl set-hostname bigbird-ncn-m001-pit
```

<a name="shasta-cfg"></a>
### Shasta-CFG

Follow [the procedures in 067-SHASTA-CFG.md](067-SHASTA-CFG.md) to
prepare the `site-init` directory for your system.

<a name="cray-site-init"></a>
### Cray-Site-Init

For `csi` usage and options, please see `csi --help` output

<a name="ca-certificate"></a>
### CA Certificate

Update CA Cert on the copied `data.json` file. Provide the path to the `data.json`, the path to
our `customizations.yaml`, and finally the `sealed_secrets.key`
```bash
pit# csi patch ca \
--cloud-init-seed-file /var/www/ephemeral/configs/data.json \
--customizations-file /var/www/ephemeral/prep/site-init/customizations.yaml \
--sealed-secret-key-file /var/www/ephemeral/prep/site-init/certs/sealed_secrets.key
```

<a name="validate-the-livecd-platform"></a>
## Validate the LiveCD platform.

Check that IPs are set for each interface:

```bash
pit# csi pit validate --network
```

<a name="livecd-services"></a>
### LiveCD Services

> Move onto **[Configure NTP](#configure-ntp)**.

Copy the config files generated earlier by `csi config init` into /etc/dnsmasq.d and /etc/conman.conf.

```bash
pit# cp /var/www/ephemeral/prep/${system_name}/dnsmasq.d/* /etc/dnsmasq.d
pit# cp /var/www/ephemeral/prep/${system_name}/conman.conf /etc/conman.conf
pit# cp /var/www/ephemeral/prep/${system_name}/basecamp/* /var/www/ephemeral/configs/
pit# systemctl restart conman
pit# systemctl restart dnsmasq
pit# systemctl start basecamp
pit# systemctl start nexus
```

<a name="configure-ntp"></a>
### Configure NTP

Start and configure NTP on the LiveCD for a fallback/recovery server:

```bash
pit# /root/bin/configure-ntp.sh
```

<a name="validate-the-livecd-services"></a>
### Validate the LiveCD Services

Now verify service health:
- dnsmasq, basecamp, and nexus should report HEALTHY and running.
- No podman container(s) should be dead.

```bash
pit# csi pit validate --services
```

> - If basecamp is dead, restart it with `systemctl restart basecamp`.
> - If dnsmasq is dead, restart it with `systemctl restart dnsmasq`.
> - If nexus is dead, restart it with `systemctl restart nexus`.

You should see two containers: nexus and basecamp

```
CONTAINER ID  IMAGE                                         COMMAND               CREATED     STATUS         PORTS   NAMES
496a2ce806d8  dtr.dev.cray.com/metal/cloud-basecamp:latest                        4 days ago  Up 4 days ago          basecamp
6fcdf2bfb58f  docker.io/sonatype/nexus3:3.25.0              sh -c ${SONATYPE_...  4 days ago  Up 4 days ago          nexus
```

<a name="verify-outside-name-resolution"></a>
### Verify Outside Name Resolution

> **`SKIP IF AIRGAP/OFFLINE`** - offline installs should skip this check entirely.

Verify you can ping quad9, or Google's, or your IT/site's DNS servers:

```bash
pit# ping 9.9.9.9
pit# ping 8.8.8.8
```

Now is a good time to also verify your local site docker registry, and RPM repository connectivity as well.

Now you can now pass GO, collect $200, and begin the [CSM Metal Install](005-CSM-METAL-INSTALL.md) page...
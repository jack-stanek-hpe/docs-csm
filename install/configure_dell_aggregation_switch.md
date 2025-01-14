

# Configure Dell Aggregation Switch

This page describes how Dell aggregation switches are configured.

Management nodes and Application nodes will be plugged into aggregation switches.

They run in a high availability pair and use VLT to provide redundancy.

## Prerequisites

- Three connections between the switches, two of these are used for the Inter switch link (ISL), and one used for the keepalive.
- Connectivity to the switch is established.
- The ISL uses 100GB ports and the keepalive will be a 25 GB port.

  Here is an example snippet from an aggregation switch on the 25G_10G tab of the SHCD spreadsheet.

  | Source | Source Label Info | Destination Label Info | Destination | Description | Notes
  | --- | --- | ---| --- | --- | --- |
  | sw-25g01 | x3105u38-j49 | x3105u39-j49 | sw-25g02 | 100g-1m-DAC | |
  | sw-25g01 | x3105u38-j50 | x3105u39-j50 | sw-25g02 | 100g-1m-DAC | |
  | sw-25g01 | x3105u38-j53 | x3105u39-j53 | sw-25g02 | 100g-1m-DAC | keepalive |


## Configure VLT


## Configure VLAN

**Cray Site Init (CSI) generates the IP addresses used by the system, below are samples only.**
The VLAN information is located in the network YAML files. Below are examples.

1. Verify the aggregation switches have VLAN interfaces in Node Management Network (NMN) and Hardware Management Network (HMN).

   Example NMN.yaml:
   
   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/NMN.yaml
   SNIPPET
     - ip_address: 10.252.0.4
       name: sw-agg-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.252.0.5
       name: sw-agg-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: NMN
     vlan_id: 2
     comment: ""
     gateway: 10.252.0.1
   ```

   Example HMN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/HMN.yaml
   SNIPPET
     - ip_address: 10.254.0.4
       name: sw-agg-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.254.0.5
       name: sw-agg-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: HMN
     vlan_id: 4
     comment: ""
     gateway: 10.254.0.1
   ```

   The following is an example of aggregation switch IP addressing based on the network .yaml files from above.

   | VLAN | Agg01 | Agg02	| Purpose |
   | --- | --- | ---| --- |
   | 2 | 10.252.0.4/17| 10.252.0.5/17 | River Node Management |
   | 4 | 10.254.0.4/17| 10.254.0.5/17 | River Hardware Management |

1. Set the NMN VLAN configuration.

   ```bash
   sw-agg-001(config)#
       vlan 2
       interface vlan2
       vsx-sync active-gateways
       ip address 10.252.0.2/17
       ip mtu 9198
       exit

   sw-agg-002(config)#
       vlan 2
       interface vlan2
       ip address 10.252.0.4/17
       ip mtu 9198
       exit
   ```

1. Set the HMN VLAN configuration.

   ```bash
   sw-agg-001(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.4/17
       ip mtu 9198
       exit

   sw-agg-002(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.5/17
       ip mtu 9198
       exit
   ```


## Configure Uplink

The uplink ports are the ports connecting the aggregation switches to the spine switches.


## Configure ACL

These ACLs are designed to block traffic from the NMN to and from the HMN.

1. Create the access list.

   **NOTE:** these are examples only, the IP addresses below need to match what was generated by CSI.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   access-list ip nmn-hmn
   seq 10 deny ip 10.252.0.0/17 10.254.0.0/17
   seq 20 deny ip 10.252.0.0/17 10.104.0.0/14
   seq 30 deny ip 10.254.0.0/17 10.252.0.0/17
   seq 40 deny ip 10.254.0.0/17 10.100.0.0/14
   seq 50 deny ip 10.100.0.0/14 10.254.0.0/17
   seq 60 deny ip 10.100.0.0/14 10.104.0.0/14
   seq 70 deny ip 10.104.0.0/14 10.252.0.0/17
   seq 80 deny ip 10.104.0.0/14 10.100.0.0/14
   90 permit any any any
   ```

1. Apply ACL to VLANs.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   interface vlan2
   ip access-group nmn-hmn in
   ip access-group nmn-hmn out
   interface vlan4
   ip access-group nmn-hmn in
   ip access-group nmn-hmn out
   interface vlan2000
   ip access-group nmn-hmn in
   ip access-group nmn-hmn out
   interface vlan3000
   ip access-group nmn-hmn in
   ip access-group nmn-hmn out
   ```

## Configure Spanning-Tree

1. Apply the following configuration to the Dell aggregation switches.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   spanning-tree vlan 1-2,4,4091 priority 61440
   ```

## Configure OSPF

OSPF is a dynamic routing protocol used to exchange routes.
It provides reachability from the MTN networks to NMN/Kubernetes networks.
The router-id used here is the NMN IP address (VLAN 2 IP).

1. Configure OSPF.
   
   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       router ospf 1
       router-id 10.252.0.x
       interface vlan2
       ip ospf 1 area 0.0.0.2
       interface vlan4
       ip ospf 1 area 0.0.0.4
   ```

## Configure NTP

The IP addresses used are the first three worker nodes on the NMN. These can be found in NMN.yaml.

1. Get current NTP configuration.

   ```bash
   sw-agg-001# show running-configuration | grep ntp
   ntp server 10.252.1.12
   ntp server 10.252.1.13
   ntp server 10.252.1.14 prefer
   ```

1. Delete any current NTP configuration.

   ```bash
   sw-agg-001# configure terminal
   sw-agg-001(config)# no ntp server 10.252.1.12
   sw-agg-001(config)# no ntp server 10.252.1.13
   sw-agg-001(config)# no ntp server 10.252.1.14
   ```

1. Add new NTP server configuration.

   ```bash
   ntp server 10.252.1.10 prefer
   ntp server 10.252.1.11
   ntp server 10.252.1.12
   ntp source vlan 2
   ```

1. Verify NTP status.

   ```bash
   sw-agg-001# show ntp associations
        remote           refid      st t when poll reach   delay   offset  jitter
   ==============================================================================
   *10.252.1.10     10.252.1.4       4 u   52   64    3    0.420   -0.262   0.023
    10.252.1.11     10.252.1.4       4 u   51   64    3    0.387   -0.225   0.043
    10.252.1.12     10.252.1.4       4 u   48   64    3    0.399   -0.222   0.050
   * master (synced), # master (unsynced), + selected, - candidate, ~ configured
   ```


## Configure DNS

1. Configure DNS.
   
   This will point to the unbound DNS server.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   ip name-server 10.92.100.225
   ```

## Configure SNMP

1. Configure SNMP.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   snmp-server group cray-reds-group 3 noauth read cray-reds-view
   snmp-server user testuser cray-reds-group 3 auth md5 testpass1 priv des testpass2
   snmp-server view cray-reds-view 1.3.6.1.2 included
   ```

## Configure Flow Control


## Configure Edge Port


These are ports that are connected to management nodes.

1. Set the worker node and master node configuration.
   
   Refer to [Cable Management Network Servers](cable_management_network_servers.md) for cabling specs.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 4 multi-chassis
       no shutdown
       description w001
       no routing
       vlan trunk native 1
       vlan trunk allowed 1-2,4,7
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/7
       no shutdown
       mtu 9198
       lag 4
       exit
   ```

1. Set the Dell storage port configuration (future use).
   
   These will be configured, but the ports will be shut down until needed.
   These are OCP and PCIe port 2 on storage nodes.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/7
       shutdown
       mtu 9198
       lag 4
       exit
   ```

1. Set the Dell LAG configuration.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 4 multi-chassis
       shutdown
       no routing
       vlan access 10
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   ```


## Configure User Access/Login/Application Node Port


- One connection will go to a NMN (VLAN2) access port. This is where the UAN will PXE boot and communicate with internal nodes (see SHCD for UAN cabling).
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a trunk port for the CAN connection.

1. Set the Dell UAN NMN configuration.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/16
       no shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

1. Set the Dell UAN CAN configuration.

   Port configuration is the same on both switches.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 17 multi-chassis
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed 7
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   ```

## Disable iSCSI

Disable iSCSI in the configuration.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   no iscsi enable
   ```


## Save Configuration

To save a configuration:

   ```bash
   sw-agg-001(config)# exit
   sw-agg-001# write memory
   ```

## Show Running Configuration


To display a running configuration:

   ```bash
   sw-agg-001# show running-config
   ```



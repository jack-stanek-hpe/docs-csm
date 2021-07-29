## Troubleshoot ConMan Blocking Access to a Node BMC

Disable ConMan if it is blocking access to a node by other means. ConMan runs on the system as a containerized service, and it is enabled by default. However, the use of ConMan to connect to a node blocks access to that node by other Serial over LAN \(SOL\) utilities or by a virtual KVM.

For information about how ConMan works, see [ConMan](/ConMan.md).

### Prerequisites

The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1. Disable the console services.
    
    Because the console services are looking for new hardware and continually verifying that console
    connections are established with all the nodes in the system, these services must be disabled
    to stop automatic console connections.

    Follow the directions in [Disable ConMan After the System Software Installation](Disable_ConMan_After_System_Software_Installation.md) to
    disable the automatic console connections.

2. Disable the SOL session.
    
    Even after the console services are disabled, the conman sol session might need to be directly disabled using `ipmitool`. Note that this is only required for River nodes as Mountain hardware
    does not use IPMI.
    
    ```
    ncn-m001# ipmitool -I lanplus -H BMC_IP -U USERNAME -P BMC_PASSWORD sol deactivate
    ```

3. Restart the console services.
    
    Refer to the directions in [Disable ConMan After the System Software Installation](Disable_ConMan_After_System_Software_Installation.md) to restart the console services when all work is complete.

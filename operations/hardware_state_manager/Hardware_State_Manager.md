## Hardware State Manager \(HSM\)

The Hardware State Manager \(HSM\) monitors and interrogates hardware components in the HPE Cray EX system, tracking hardware state and inventory information, and making it available via REST queries and message bus events when changes occur.

In the HPE Cray EX 1.4 release, v1 of the HSM API has begun its deprecation process in favor of the new HSM v2 API. Refer to the HSM API documentation for more information on the changes.

### Hardware State Transitions

The following table describes how to interpret when the state of hardware changes:

| Old State | New State     | Reason                                                       |
| --------- | ------------- | ------------------------------------------------------------ |
| Ready     | Standby       | HBTD if node has many missed heartbeats                      |
| Ready     | Ready/Warning | HBTD if node has a few missed heartbeats                     |
| Standby   | Ready         | HBTD node re-starts heartbeating                             |
| On        | Ready         | HBTD node started heartbeating                               |
| Off       | Ready         | HBTD sees heartbeats before Redfish Event (On)               |
| Standby   | On            | Redfish Event (On) or if re-discovered while in the standby state |
| Off       | On            | Redfish Event (On)                                           |
| Standby   | Off           | Redfish Event (Off)                                          |
| Ready     | Off           | Redfish Event (Off)                                          |
| On        | Off           | Redfish Event (Off)                                          |
| Any State | Empty         | Redfish Endpoint is disabled meaning component removal       |

Generally, nodes transition from `Off` to `On` to `Ready` when going from `Off` to booted, and from `Ready` to `Ready/Warning` to `Standby` to `Off` when shut down.


### Table of Contents

* [Hardware Management Services (HMS) Locking API](Hardware_Management_Services_HMS_Locking_API.md)
  * [NCN and Management Node Locking](NCN_and_Management_Node_Locking.md)
  * [Manage HMS Locks](Manage_HMS_Locks.md)
* [Component Groups and Partitions](Component_Groups_and_Partitions.md)
  * [Manage Component Groups](Manage_Component_Groups.md)
  * [Component Group Members](Component_Group_Members.md)
  * [Manage Component Partitions](Manage_Component_Partitions.md)
  * [Component Partition Members](Component_Partition_Members.md)
  * [Component Memberships](Component_Memberships.md)
* [Hardware State Manager (HSM) State and Flag Fields](Hardware_State_Manager_HSM_State_and_Flag_Fields.md)
* [Add an NCN to the HSM Database](Add_an_NCN_to_the_HSM_Database.md)
* [Add a Switch to the HSM Database](Add_a_Switch_to_the_HSM_Database.md)
* [Manage NodeMaps with HSM](Manage_NodeMaps_with_HSM.md)
* [HSM Subroles](HSM_Subroles.md)
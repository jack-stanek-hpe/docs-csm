## Recipes

The following example JSON files are useful to reference when updating specific hardware components. In all of these examples, the `overrrideDryrun` field will be set to `false`; set them to `true` to perform a live update.

When updating an entire system, walk down the device hierarchy component type by component type, starting first with 'Routers' (switches), proceeding to Chassis, and then finally to Nodes. While this is not strictly necessary, it does help eliminate confusion.

Refer to [FAS Filters](FAS_Filters.md) for more information on the content used in the example JSON files.

---
<a name="manufacturer-cray"></a>

### Manufacturer : Cray

<a name="cray-device-type-routerbmc-target-bmc"></a>

#### Device Type: RouterBMC |  Target: BMC

The BMC on the RouterBMC for a Cray includes the ASIC.  

```json
{
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"stateComponentFilter": {
    "deviceTypes": [
      "routerBMC"
    ]
},
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Columbia and/or Colorado router BMC"
  }
}
```

<a name="cray-device-type-chassisbmc-target-bmc"></a>

#### Device Type: ChassisBMC | Target: BMC

**IMPORTANT**: Before updating a CMM, make sure all slot and rectifier power is off. The hms-discovery job must also be stopped before updates and restarted after updates are complete.

* Stop hms-discovery job: `kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":true}}'`
* Start hms-discovery job: `kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":false}}'`

```json
{
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"stateComponentFilter": {
    "deviceTypes": [
      "chassisBMC"
    ]
},
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Cray Chassis Controllers"
  }
}
```

<a name="cray-device-type-nodebmc-target-bmc"></a>

#### Device Type: NodeBMC | Target: BMC


```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Olympus node BMCs"
  }
}
```

<a name="cray-device-type-nodebmc-target-nodebios"></a>

#### Device Type: NodeBMC | Target: NodeBIOS

**IMPORTANT:**
* The Nodes themselves must be powered **off** in order to update the BIOS on the nodes. The BMC will still have power and will perform the update.
* When the BMC is updated or rebooted after updating the Node0.BIOS and/or Node1.BIOS liquid-cooled nodes, the node BIOS version will not report the new version string until the nodes are powered back on. It is recommended that the Node0/1 BIOS be updated in a separate action, either before or after a BMC update and the nodes are powered back on after a BIOS update. The liquid-cooled nodes must be powered off for the BIOS to be updated.

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.BIOS",
      "Node1.BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node BIOS"
  }
}
```

**NOTE:** If this update does not work as expected, follow the [Compute Node BIOS Workaround for HPE CRAY EX425](FAS_Use_Cases.md#cn-workaround) procedure.


<a name="cray-device-type-nodebmc-target-redstone-fpga"></a>

#### Device Type: NodeBMC | Target: Redstone FPGA

**IMPORTANT:**
* The Nodes themselves must be powered **on** in order to update the firmware of the Redstone FPGA on the nodes.
* If updating FPGAs fails because of "No Image available", update using the "Override an Image for an Update" procedure in [FAS Admin Procedures](FAS_Admin_Procedures.md). Find the imageID using the following command: `cray fas images list --format json | jq '.[] | .[] | select(.target=="Node0.AccFPGA0")'`

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.AccFPGA0",
      "Node1.AccFPGA0"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node Redstone FPGA"
  }
}
```

---

<a name="manufacturer-hpe"></a>

### Manufacturer: HPE

<a name="hpe-device-type-nodebmc-target--aka-bmc"></a>

#### Device Type: NodeBMC | Target: `iLO 5` aka BMC

```json
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "1"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node iLO 5"
  }
}
```

**NOTE:** `1` must be used as the `target` to indicate `iLO 5`. 


<a name="hpe-device-type-nodebmc-target--aka-bios"></a>

#### Device Type: NodeBMC | Target: `System ROM` aka BIOS

**IMPORTANT:** 
* If updating the System ROM of an NCN, the NTP and DNS server values will be lost and must be restored. For NCNs **other than m001** this can be done using the `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh` script. Use the `-h` option to get a list of command line options required to restore the NTP and DNS values.
* Node should be powered on for System ROM update and will need to be rebooted to use the updated BIOS.


```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "NodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "2"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node system rom"
  }
}
```

**NOTE:** 
* `2` must be used as the `target` to indicate `System ROM`. 
* Update of System ROM may report as an error when it actually succeeded because of an incorrect string in the image metadata in FAS. Manually check the update version to get around this error.


---

<a name="manufacturer-gigabyte"></a>

### Manufacturer: Gigabyte

<a name="gb-device-type-nodebmc-target-bmc"></a>

#### Device Type: NodeBMC | Target: BMC


```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 2000,
    "description": "Dryrun upgrade of Gigabyte node BMCs"
  }
}
```

**NOTE:** The timeLimit is `2000` because the Gigabytes can take a lot longer to update. 


<a name="gb-device-type-nodebmc-target-bios"></a>

#### Device Type: NodeBMC | Target: BIOS

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 2000,
    "description": "Dryrun upgrade of Gigabyte node BIOS"
  }
}
```

### Update Non-Compute Nodes (NCNs)

NCNs are compute blades. The current NCNs in use are manufactured by Gigabyte or HPE. Use the `NodeBMC` examples in this section when updating NCN firmware. Include the `xname` parameter as part of the `stateComponentFilter` to target **ONLY** the xnames that have been separately identified as NCNs.  

**WARNING:** Updating more than one NCN at a time **MAY** cause system instability. Be sure to follow the correct process for updating NCNs. Firmware updates have the capacity to harm the system.


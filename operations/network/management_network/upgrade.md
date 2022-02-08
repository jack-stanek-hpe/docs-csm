# Upgrade

Upgrading to a new CSM version.

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation: 

1. [Collect data](collect_data.md)
    - Collect system data.
1. [Update management network firmware](update_management_network_firmware.md)
    - Upgrade switch firmware to specified firmware version.
1. [Backup custom config](backup_custom_config.md)
    - If the system had a previous version of CSM on it, you need to backup all custom configuration and credential configuration.  This procedure can be found on the.
1. [Config management](config_management.md)
    - Backup switch configs.
1. [Wipe mgmt switches](wipe_mgmt_switches.md)
    - If the switches have any configuration, it is recommenced to erase it before any configuration.
1. [Validate the SHCD](validate_shcd.md)
    - The SHCD defines the topology of a Shasta system, this is needed when generating switch configs.
1. [Generate switch configs](generate_switch_configs.md)
    - Generate the switch configuration file(s)
1. [Apply switch configs](apply_switch_configs.md)  
    - Applying the configuration to switch.
1. [Validate switch configs](validate_switch_configs.md) 
    - Checks differences between generated configs and the configs on the system.
1. [Network tests](network_tests.md)
    - Run a suite of tests against the management network switches.
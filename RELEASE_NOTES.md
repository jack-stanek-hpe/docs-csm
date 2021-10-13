# Cray System Management (CSM) - Release Notes
## What’s new
## Bug Fixes
## Known Issues
- Cfs_session_stuck_in_pending: Under some circumstances CFS sessions can get stuck in a pending state, never completing and potentially blocking other sessions.  This addresses cleaning up those sessions.
- Conman_pod_kubernetes_copy_fails: The kubernetes copy file command fails when attempting to copy log files from the cray-conman pod.
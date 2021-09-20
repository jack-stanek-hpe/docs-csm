# NCN Development

This page will help you if you are trying to test new images on a metal system. Here you can
find a basic flow for iterative boots.

> We assume you are internally developing; these scripts are for internal use only.

1. Get your Image ID
    > `-k` for Kubernetes, `-s` for storage/ceph

    ```bash
   pit# /root/bin/get-sqfs.sh -k 9683117-1609280754169
   pit# /root/bin/get-sqfs.sh -s c46624e-1609524120402
   ```

2. Set your Image IDs
    > This finds the newest pair, so it will find the last downloaded set (i.e. your set of images). 
    ```bash
   pit# /root/bin/set-sqfs-links.sh
   ```

3. (Re)boot the node(s) you want to test.

4. One can easily follow along using conman. Run `conman -q` to see available consoles.
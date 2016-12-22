# lvm 

This role allows for administering logical groups and volumes simultaneously.
Removal of the respective entities is not possible. For that purpose, please rely
on the ansible core modules `lvg` and `lvol`.

## configuration

The role expects a variable `lvm` in the top-level scope. An example config follows below:

```yaml
lvm:
  vg00:
    pvs: [/dev/sda5]
    lvs:
      lvroot:
        size: 20G
        mountpoint: /
      lvtmp:
        size: 20G
        mountpoint: /tmp
        owner: root
        group: root
        mode: '1777'
  vg01:
    pvs: [/dev/sd1, /dev/sdx5]
    lvs:
      lvhome:
        size: 40G
        mountpoint: /home
        reserved_blocks_percentage: 1%  # the '%'-sign is optional
      lvopt:
        size: 20G
        mountpoint: /opt
        fstype: zfs  # be courageous
```

Using `hash_behaviour = merge` allows for updating the above structure on group or host level.

#### resize filesystems

When increasing the `size` of an `lv`, the volume will get resized. That only works for ext3 and ext4 filesystems.

#### filesystem type

The filesystem type can  be specified per logical volume using the `fstype` key. If absent, it defaults
to the value of the global variable `lvm_default_fstype`. The role specifies `lvm_default_fstype: ext4`
as default variable.

## todo

* have `pv`s created by this role, too
* allow for resizing of non-ext3/4 filesystems

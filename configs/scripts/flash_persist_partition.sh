#!/system/bin/sh -e

PERSIST_FSTYPE=vfat
PERSIST_IMAGE_GZ=/system/etc/persist.img.gz
PERSIST_PARTITION=/dev/block/by-name/persist
PERSIST_MOUNTPOINT=/mnt/vendor/_persist

if [ -e $PERSIST_PARTITION ]; then
    if ! grep -q "$PERSIST_MOUNTPOINT $PERSIST_FSTYPE" /proc/mounts; then
        zcat $PERSIST_IMAGE_GZ | dd of=$PERSIST_PARTITION bs=1M
    fi
fi

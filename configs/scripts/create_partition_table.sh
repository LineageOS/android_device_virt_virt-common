# Do not set interpreter, this script will be executed either on build host or in android recovery

SGDISK_EXEC=$1
TARGET=$2
DISK_NAME=$3
AB_OTA_UPDATER=$4
SUPER_SIZE=$5

if [ ! -x "$SGDISK_EXEC" ] || [ ! -w "$TARGET" ] || [ -z "$DISK_NAME" ]; then
    exit 1
fi

which setprop > /dev/null && setprop vendor.create_partition_table.start 1

if [ -e "${TARGET}2" ]; then
    HAVE_INITIAL_PARTITION_TABLE=1
fi

case "$DISK_NAME" in
    "sda"|"vda")
        [ "$HAVE_INITIAL_PARTITION_TABLE" = "1" ] || $SGDISK_EXEC --zap-all $TARGET
        if [ "$AB_OTA_UPDATER" = "true" ]; then
            if [ "$HAVE_INITIAL_PARTITION_TABLE" != "1" ]; then
                $SGDISK_EXEC --new=1:0:+128M --typecode=1:ef00 --change-name=1:EFI $TARGET
                # https://source.android.com/docs/core/ota/dynamic_partitions/how_to_size_super#full_super_without_compression
                $SGDISK_EXEC --new=2:0:+12G --change-name=2:super $TARGET
                $SGDISK_EXEC --new=3:0:+1M --change-name=3:misc $TARGET
                $SGDISK_EXEC --new=4:0:+16M --change-name=4:persist $TARGET
                $SGDISK_EXEC --new=5:0:+32M --change-name=5:metadata $TARGET
                $SGDISK_EXEC --new=6:0:+128M --change-name=6:firmware $TARGET
                $SGDISK_EXEC --new=7:0:+100M --change-name=7:vendor_boot_a $TARGET
                $SGDISK_EXEC --new=8:0:+100M --change-name=8:vendor_boot_b $TARGET
                $SGDISK_EXEC --new=9:0:+80M --change-name=9:boot_a $TARGET
                $SGDISK_EXEC --new=10:0:+80M --change-name=10:boot_b $TARGET
            fi
            $SGDISK_EXEC --change-name=7:vendor_boot_a $TARGET
            $SGDISK_EXEC --change-name=8:vendor_boot_b $TARGET
            [ -e "${TARGET}11" ] || $SGDISK_EXEC --new=11:0:+4M --typecode=11:ef02 --change-name=11:BIOS $TARGET
        else
            if [ "$HAVE_INITIAL_PARTITION_TABLE" != "1" ]; then
                $SGDISK_EXEC --new=1:0:+256M --typecode=1:ef00 --change-name=1:EFI $TARGET
                if [ "$SUPER_SIZE" = "3221225472" ]; then
                    $SGDISK_EXEC --new=2:0:+3G --change-name=2:super $TARGET
                else
                    $SGDISK_EXEC --new=2:0:+4G --change-name=2:super $TARGET
                fi
                $SGDISK_EXEC --new=3:0:+1M --change-name=3:misc $TARGET
                $SGDISK_EXEC --new=4:0:+32M --change-name=4:metadata $TARGET
                $SGDISK_EXEC --new=5:0:+50M --change-name=5:cache $TARGET
                $SGDISK_EXEC --new=6:0:+64M --change-name=6:boot $TARGET
                $SGDISK_EXEC --new=7:0:+64M --change-name=7:recovery $TARGET
                $SGDISK_EXEC --new=8:0:+128M --change-name=8:firmware $TARGET
                $SGDISK_EXEC --new=9:0:+16M --change-name=9:persist $TARGET
            fi
            [ -e "${TARGET}10" ] || $SGDISK_EXEC --new=10:0:+4M --typecode=10:ef02 --change-name=10:BIOS $TARGET
            [ -e "${TARGET}11" ] || $SGDISK_EXEC --new=11:0:+100M --change-name=11:vendor_boot $TARGET
        fi
        ;;
    *)
        exit 1
        ;;
esac

if [ -f "/system/etc/MBR.img" ]; then
    dd if=/system/etc/MBR.img of=$TARGET bs=446 count=1
fi

if [ -f "/system/etc/super_empty_raw.img" ] && ! dd if=/dev/block/by-name/super bs=256k count=1|strings|grep virt_dynamic_partitions > /dev/null; then
    dd if=/system/etc/super_empty_raw.img of=/dev/block/by-name/super
fi

which setprop > /dev/null && setprop vendor.create_partition_table.finish 1

exit 0

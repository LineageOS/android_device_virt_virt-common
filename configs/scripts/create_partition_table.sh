# Do not set interpreter, this script will be executed either on build host or in android recovery

SGDISK_EXEC=$1
TARGET=$2
DISK_NAME=$3
AB_OTA_UPDATER=$4
SUPER_SIZE=$5

if [ ! -x "$SGDISK_EXEC" ] || [ ! -w "$TARGET" ] || [ -z "$DISK_NAME" ]; then
    exit 1
fi

if [ -e "${TARGET}2" ]; then
    SKIP_INIT=true
fi

case "$DISK_NAME" in
    "sda"|"vda")
        [ "$SKIP_INIT" = "true" ] || $SGDISK_EXEC --zap-all $TARGET
        if [ "$AB_OTA_UPDATER" = "true" ]; then
            if [ "$SKIP_INIT" != "true" ]; then
                $SGDISK_EXEC --new=1:0:+128M --typecode=1:ef00 --change-name=1:EFI $TARGET
                # https://source.android.com/docs/core/ota/dynamic_partitions/how_to_size_super#full_super_without_compression
                $SGDISK_EXEC --new=2:0:+12G --change-name=2:super $TARGET
                $SGDISK_EXEC --new=3:0:+1M --change-name=3:misc $TARGET
                $SGDISK_EXEC --new=4:0:+16M --change-name=4:persist $TARGET
                $SGDISK_EXEC --new=5:0:+32M --change-name=5:metadata $TARGET
                $SGDISK_EXEC --new=6:0:+128M --change-name=6:firmware $TARGET
                $SGDISK_EXEC --new=7:0:+100M --change-name=7:grub_boot_a $TARGET
                $SGDISK_EXEC --new=8:0:+100M --change-name=8:grub_boot_b $TARGET
                $SGDISK_EXEC --new=9:0:+80M --change-name=9:boot_a $TARGET
                $SGDISK_EXEC --new=10:0:+80M --change-name=10:boot_b $TARGET
            fi
            if [ ! -e "${TARGET}11" ]; then
                $SGDISK_EXEC --new=11:0:+1M --change-name=11:vbmeta_a $TARGET
                $SGDISK_EXEC --new=12:0:+1M --change-name=12:vbmeta_b $TARGET
                $SGDISK_EXEC --new=13:0:+1M --change-name=13:vbmeta_system_a $TARGET
                $SGDISK_EXEC --new=14:0:+1M --change-name=14:vbmeta_system_b $TARGET
                $SGDISK_EXEC --new=15:0:+1M --change-name=15:vbmeta_vendor_a $TARGET
                $SGDISK_EXEC --new=16:0:+1M --change-name=16:vbmeta_vendor_b $TARGET
            fi
        else
            if [ "$SKIP_INIT" != "true" ]; then
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
            if [ ! -e "${TARGET}10" ]; then
                $SGDISK_EXEC --new=10:0:+1M --change-name=10:vbmeta $TARGET
                $SGDISK_EXEC --new=11:0:+1M --change-name=11:vbmeta_system $TARGET
                $SGDISK_EXEC --new=12:0:+1M --change-name=12:vbmeta_vendor $TARGET
            fi
        fi
        ;;
    *)
        exit 1
        ;;
esac

which setprop > /dev/null && setprop vendor.create_partition_table.finish 1

exit 0

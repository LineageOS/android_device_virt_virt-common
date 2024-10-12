# Do not set interpreter, this script will be executed either on build host or in android recovery

SGDISK_EXEC=$1
TARGET=$2
DISK_NAME=$3
AB_OTA_UPDATER=$4
SUPER_SIZE=$5

if [ ! -x "$SGDISK_EXEC" ] || [ ! -w "$TARGET" ] || [ -z "$DISK_NAME" ]; then
    exit 1
fi

case "$DISK_NAME" in
    "sda"|"vda")
        $SGDISK_EXEC --zap-all $TARGET
        if [ "$AB_OTA_UPDATER" = "true" ]; then
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
        else
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
        ;;
    *)
        exit 1
        ;;
esac

exit 0

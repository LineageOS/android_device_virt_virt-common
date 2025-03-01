#!/usr/bin/python3

import os
import subprocess
import sys

def write_disk_partitions(output_file, product_out, disk_name, board_super_partition_size, ab_ota_updater, write_partitions):
    sector_info = {
        "vda": {
            "sector_size": 512,
        },
    }

    if ab_ota_updater == "true":
        sector_info["vda"].update({
            "sectors": 27262976,
            "partitions": {
                "EFI": {"start": 2048, "sectors": 262144, "ab": True, "fake_ab": True},
                "super": {"start": 264192, "sectors": 25165824},
                "misc": {"start": 25430016, "sectors": 2048},
                "persist": {"start": 25432064, "sectors": 32768},
                "metadata": {"start": 25464832, "sectors": 65536},
                "firmware": {"start": 25530368, "sectors": 262144},
                "grub_boot": {"start": 25792512, "sectors": 204800, "ab": True},
                "boot": {"start": 26202112, "sectors": 163840, "ab": True},
                "BIOS": {"start": 26529792, "sectors": 8192, "ab": True, "fake_ab": True},
            },
        })
    else:
        if board_super_partition_size == "3221225472":
            sector_info["vda"].update({
                "sectors": 8388608,
                "partitions": {
                    "EFI": {"start": 2048, "sectors": 524288},
                    "super": {"start": 526336, "sectors": 6291456},
                    "misc": {"start": 6817792, "sectors": 2048},
                    "metadata": {"start": 6819840, "sectors": 65536},
                    "cache": {"start": 6885376, "sectors": 102400},
                    "boot": {"start": 6987776, "sectors": 131072},
                    "recovery": {"start": 7118848, "sectors": 131072},
                    "firmware": {"start": 7249920, "sectors": 262144},
                    "persist": {"start": 7512064, "sectors": 32768},
                    "BIOS": {"start": 7544832, "sectors": 8192},
                },
            })
        elif board_super_partition_size == "4294967296":
            sector_info["vda"].update({
                "sectors": 10485760,
                "partitions": {
                    "EFI": {"start": 2048, "sectors": 524288},
                    "super": {"start": 526336, "sectors": 8388608},
                    "misc": {"start": 8925184, "sectors": 2048},
                    "metadata": {"start": 8927232, "sectors": 65536},
                    "cache": {"start": 8992768, "sectors": 102400},
                    "boot": {"start": 9096960, "sectors": 131072},
                    "recovery": {"start": 9228032, "sectors": 131072},
                    "firmware": {"start": 9359104, "sectors": 262144},
                    "persist": {"start": 9621248, "sectors": 32768},
                    "BIOS": {"start": 9654016, "sectors": 8192},
                },
            })
        else:
            print(f"Error: Unsupported BOARD_SUPER_PARTITION_SIZE for vda disk image creation: {board_super_partition_size}")
            sys.exit(1)

    disk = sector_info["vda"]

    for partition_name in write_partitions.split():
        if partition_name in disk["partitions"]:
            partition = disk["partitions"][partition_name]
            if partition.get("fake_ab", False):
                ab_slots = [""] # Only write once for fake A/B
            else:
                ab_slots = ["_a", "_b"] if partition.get("ab", False) else [""]

            for ab_slot_suffix in ab_slots:
                start_sector = partition["start"]
                sectors = partition["sectors"]

                if ab_slot_suffix == "_b":
                    start_sector += sectors # Calculate start sector for slot B

                if ab_slot_suffix:
                    sectors = disk["partitions"][partition_name]["sectors"]

                start_byte = start_sector * disk["sector_size"]
                partition_size_byte = sectors * disk["sector_size"]
                image_path = os.path.join(product_out, f"{partition_name}.img") # Remove A/B from source image name.
                image_size_byte = os.path.getsize(image_path)

                if image_size_byte > partition_size_byte:
                    print(f"Error: Image {image_path} is larger than partition {partition_name}{ab_slot_suffix}")
                    sys.exit(1)

                seek_megabytes = start_byte // 4194304 # 4MB = 4194304 bytes
                count_megabytes = (image_size_byte // 4194304) + (1 if image_size_byte % 4194304 else 0)

                subprocess.run([
                    "dd", f"if={image_path}", f"of={output_file}", "bs=4M", f"seek={seek_megabytes}",
                    f"count={count_megabytes}", "conv=notrunc"
                ])

if __name__ == "__main__":
    output_file = sys.argv[1]
    product_out = sys.argv[2]
    disk_name = sys.argv[3]
    board_super_partition_size = sys.argv[4]
    ab_ota_updater = sys.argv[5]
    write_partitions = sys.argv[6]

    write_disk_partitions(output_file, product_out, disk_name, board_super_partition_size, ab_ota_updater, write_partitions)

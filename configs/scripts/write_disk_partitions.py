#!/usr/bin/python3

import os
import subprocess
import sys

def write_disk_partitions(output_file, product_out, disk_name, board_super_partition_size, ab_ota_updater, write_partitions):
    print(f"INFO: Starting write_disk_partitions with:")
    print(f"INFO:   output_file: {output_file}")
    print(f"INFO:   product_out: {product_out}")
    print(f"INFO:   disk_name: {disk_name}")
    print(f"INFO:   board_super_partition_size: {board_super_partition_size}")
    print(f"INFO:   ab_ota_updater: {ab_ota_updater}")
    print(f"INFO:   write_partitions: {write_partitions}")

    sector_info = {
        "vda": {
            "sector_size": 512,
        },
    }

    if ab_ota_updater == "true":
        print("INFO: AB_OTA_UPDATER is true")
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
        print("INFO: AB_OTA_UPDATER is false")
        if board_super_partition_size == "3221225472":
            print("INFO: BOARD_SUPER_PARTITION_SIZE is 3221225472")
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
            print("INFO: BOARD_SUPER_PARTITION_SIZE is 4294967296")
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
            print(f"ERROR: Unsupported BOARD_SUPER_PARTITION_SIZE for vda disk image creation: {board_super_partition_size}")
            sys.exit(1)

    disk = sector_info["vda"]
    sector_size = disk["sector_size"]

    write_partitions_list = [part for part in write_partitions.split() if part]
    print(f"INFO: write_partitions_list: {write_partitions_list}")

    for partition_name in write_partitions_list:
        if partition_name in disk["partitions"]:
            partition = disk["partitions"][partition_name]
            if partition.get("fake_ab", False):
                ab_slots = [""] # Only write once for fake A/B
            else:
                ab_slots = ["_a", "_b"] if partition.get("ab", False) else [""]

            print(f"INFO: Processing partition: {partition_name}, ab_slots: {ab_slots}")

            for ab_slot_suffix in ab_slots:
                start_sector = partition["start"]
                sectors = partition["sectors"]

                if ab_slot_suffix == "_b":
                    start_sector += sectors # Calculate start sector for slot B

                if ab_slot_suffix:
                    sectors = disk["partitions"][partition_name]["sectors"]

                start_byte = start_sector * sector_size
                partition_size_byte = sectors * sector_size
                image_path = os.path.join(product_out, f"{partition_name}.img")
                image_size_byte = os.path.getsize(image_path)

                print(f"INFO:   Image path: {image_path}, size: {image_size_byte}, partition size: {partition_size_byte}, start_sector: {start_sector}, start_byte: {start_byte}")

                if image_size_byte > partition_size_byte:
                    print(f"ERROR: Image {image_path} is larger than partition {partition_name}{ab_slot_suffix}")
                    sys.exit(1)

                if start_byte % 1048576 == 0:  # 1MB alignment
                    seek_megabytes = start_byte // 1048576
                    count_megabytes = (image_size_byte + 1048575) // 1048576

                    print(f"INFO:   Writing {image_size_byte} bytes using bs=1M, seek: {seek_megabytes}, count: {count_megabytes}")

                    subprocess.run([
                        "dd", f"if={image_path}", f"of={output_file}", "bs=1M", f"seek={seek_megabytes}",
                        f"count={count_megabytes}", "conv=notrunc"
                    ])
                else:  # Non-1MB alignment
                    print(f"INFO:   Partition not 1MB aligned, writing using bs={sector_size}")
                    subprocess.run([
                        "dd", f"if={image_path}", f"of={output_file}", f"bs={sector_size}", f"seek={start_byte // sector_size}",
                        f"count={image_size_byte // sector_size + 1 if image_size_byte % sector_size else image_size_byte // sector_size}",
                        "conv=notrunc"
                    ])

                print(f"INFO:   dd command complete for partition {partition_name}{ab_slot_suffix}")

if __name__ == "__main__":
    output_file = sys.argv[1]
    product_out = sys.argv[2]
    disk_name = sys.argv[3]
    board_super_partition_size = sys.argv[4]
    ab_ota_updater = sys.argv[5]
    write_partitions = sys.argv[6]

    write_disk_partitions(output_file, product_out, disk_name, board_super_partition_size, ab_ota_updater, write_partitions)

#!python3

import os
import math
import argparse

def calculate_fat32_image_size(file_paths, debug=False):
    """
    Calculates the minimum size of a FAT32 image required to store the given files and directories,
    including estimations for metadata overhead.

    Args:
        file_paths: A list of file and directory paths.
        debug: If True, prints detailed information.

    Returns:
        The minimum size of the FAT32 image in bytes.
    """

    total_data_size = 0
    num_files = 0
    num_dirs = 0

    for path in file_paths:
        if os.path.isfile(path):
            total_data_size += os.path.getsize(path)
            num_files +=1
        elif os.path.isdir(path):
            num_dirs+=1
            for root, dirs, files in os.walk(path):
                num_dirs += len(dirs)
                num_files += len(files)
                for file in files:
                    file_path = os.path.join(root, file)
                    total_data_size += os.path.getsize(file_path)
        else:
            print(f"Warning: Path '{path}' not found.")

    cluster_size = 32 * 1024  # 32 KB

    num_data_clusters = math.ceil(total_data_size / cluster_size)

    directory_entry_size = 32
    fat_entry_size = 4 * 2 # two copies of FAT
    file_name_overhead = 16
    directory_overhead = 64

    directory_metadata_size = (num_files + num_dirs) * directory_entry_size + num_dirs * directory_overhead
    fat_metadata_size = num_data_clusters * fat_entry_size
    file_name_metadata_size = num_files * file_name_overhead

    total_metadata_size = directory_metadata_size + fat_metadata_size + file_name_metadata_size

    total_size = total_data_size + total_metadata_size
    num_total_clusters = math.ceil(total_size/cluster_size)
    image_size = num_total_clusters * cluster_size

    if debug:
        print(f"Total data size: {total_data_size} bytes")
        print(f"Number of files: {num_files}")
        print(f"Number of directories: {num_dirs}")
        print(f"Directory metadata size: {directory_metadata_size} bytes")
        print(f"FAT metadata size: {fat_metadata_size} bytes")
        print(f"File name metadata size: {file_name_metadata_size} bytes")
        print(f"Total metadata size: {total_metadata_size} bytes")
        print(f"Total size: {total_size} bytes")
        print(f"Number of total clusters: {num_total_clusters}")
        print(f"Minimum FAT32 image size (with metadata): {image_size} bytes ({image_size / (1024 * 1024):.2f} MB)")

    return image_size / (1024 * 1024) #return size in MiB

def main():
    parser = argparse.ArgumentParser(description="Calculate minimum FAT32 image size with metadata.")
    parser.add_argument("paths", nargs="+", help="File and directory paths.")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug output.")
    parser.add_argument("-l", "--label", type=str, default="", help="Volume label. Quirks may apply depending on volume label.")
    args = parser.parse_args()

    image_size_mib = calculate_fat32_image_size(args.paths, args.debug)
    image_size_mib += 8 # reserved

    # Quirks
    if args.label == "boot":
        if image_size_mib < 34:
            image_size_mib = 34

    print(f"{image_size_mib:.0f}")

if __name__ == "__main__":
    main()

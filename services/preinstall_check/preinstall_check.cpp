#include <android-base/log.h>
#include <android-base/properties.h>
#include <android-base/strings.h>
#include <cutils/ashmem.h>
#include <sys/statvfs.h>
#include <sys/sysinfo.h>
#include <xf86drm.h>

#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <fstream>
#include <iostream>
#include <list>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using android::base::GetProperty;
using android::base::SetProperty;

using android::base::EndsWith;
using android::base::Split;
using android::base::StartsWith;

using PartitionNameSizeMapType = std::map<std::string, unsigned long long>;

#define MB(in) (in * 1024ull * 1024)
#define GB(in) (MB(in) * 1024ull)

#ifdef AB_OTA_UPDATER
PartitionNameSizeMapType kBootDiskPartitionNameSizeMap = {
        {"EFI", MB(128)},         {"super", SUPER_PARTITION_SIZE},
        {"misc", MB(1)},          {"persist", MB(16)},
        {"metadata", MB(32)},     {"firmware", MB(128)},
        {"grub_boot_a", MB(100)}, {"grub_boot_b", MB(100)},
        {"boot_a", MB(80)},       {"boot_b", MB(80)},
};
#else
PartitionNameSizeMapType kBootDiskPartitionNameSizeMap = {
        {"EFI", MB(256)},     {"super", SUPER_PARTITION_SIZE},
        {"misc", MB(1)},      {"metadata", MB(32)},
        {"cache", MB(50)},    {"boot", MB(64)},
        {"recovery", MB(64)}, {"firmware", MB(128)},
        {"persist", MB(16)},
};
#endif

const std::string kErrorIcon =
        "\n"
        "            ##\n"
        "           ####\n"
        "          ######\n"
        "         ########\n"
        "        ####  ####\n"
        "       #####  #####\n"
        "      ######  ######\n"
        "     #######  #######\n"
        "    ########  ########\n"
        "   #########  #########\n"
        "  ######################\n"
        " ###########  ###########\n"
        "##########################\n";

std::list<std::string> gErrorLines;

std::vector<std::string> parseCpuinfoFlags() {
    std::ifstream cpuinfo_file("/proc/cpuinfo");
    std::vector<std::string> flags;

    if (cpuinfo_file.is_open()) {
        std::string line;
        while (std::getline(cpuinfo_file, line)) {
            if (line.find("flags") == 0) {
                std::string value = line.substr(line.find(":") + 2);
                flags = Split(value, " ");
                break;
            }
        }
        cpuinfo_file.close();
    } else {
        LOG(ERROR) << "Failed to open /proc/cpuinfo";
    }

    return flags;
}

void checkCpuFlags() {
#if defined(__x86_64__)
    auto cpu_flags = parseCpuinfoFlags();
    if (!cpu_flags.empty()) {
        if (std::find(cpu_flags.begin(), cpu_flags.end(), "sse4_2") == cpu_flags.end()) {
            gErrorLines.push_back(
                    "This CPU model does not support SSE 4.2 instruction set. Please select a CPU "
                    "model that supports it.");
        }
    }
#endif
    return;
}

void checkBootDiskPartitions() {
    // Check whether if the disk is accessible
    std::string disk_path = "/dev/block/" + BOOT_DISK_NAME;
    int disk_fd = open(disk_path.c_str(), O_RDONLY);
    if (disk_fd < 0) {
        gErrorLines.push_back("Failed to open boot disk " + BOOT_DISK_NAME +
                              ". Is the disk not created yet or attached to different bus?");
        return;
    }
    close(disk_fd);

    int partition_num = 0;
    unsigned long long all_partitions_size = 0;
    for (const auto& it : kBootDiskPartitionNameSizeMap) {
        partition_num++;
        all_partitions_size += it->second;

        // firmware partition is optional and ignorable
        if (it->first == "firmware") continue;

        std::string part_byname_path = "/dev/block/by-name/" + it->first;

        // Check whether if the partition is accessible
        int part_fd = open(part_byname_path.c_str(), O_RDONLY);
        if (part_fd < 0) {
            gErrorLines.push_back("Failed to open partition " + it->first);
            continue;
        }
        close(part_fd);

        char part_realpath_buf[20];
        ssize_t part_realpath_buf_len = readlink(part_byname_path.c_str(), &part_realpath_buf,
                                                 sizeof(part_realpath_buf) - 1);
        part_realpath_buf[part_realpath_len] = '\0';
        if (part_realpath_buf_len == -1) {
            LOG(ERROR) << "Failed to readlink() for " << part_byname_path;
        } else {
            std::string part_realpath = std::string(part_realpath_buf);

            // Check whether if the partition belongs to the boot disk
            // and whether if the partition number is correct
            if (!StartsWith(part_realpath, "/dev/block/" + std::string(BOOT_DISK_NAME))) {
                gErrorLines.push_back("Partition " + it->first + " does not belong to boot disk " +
                                      BOOT_DISK_NAME + ". Are the disks in incorrect order?");
            } else if (!EndsWith(part_realpath,
                                 std::string(BOOT_DISK_NAME) + std::to_string(partition_num))) {
                gErrorLines.push_back("Partition " + it->first +
                                      " has incorrect number: " + std::to_string(partition_num));
            }

            // Check partition size
            struct statvfs part_stat;
            if (statvfs(part_realpath_buf, &part_stat) == 0) {
                unsigned long long part_size = part_stat.f_blocks * part_stat.f_bsize;
                if (part_size < it->second) {
                    gErrorLines.push_back("Partition " + it->first + " is too small");
                }
            } else {
                LOG(ERROR) << "Failed to statvfs() for " << part_realpath;
            }
        }
    }

    // Check disk size
    struct statvfs disk_stat;
    if (statvfs(disk_path.c_str(), &disk_stat) == 0) {
        unsigned long long disk_size = disk_stat.f_blocks * disk_stat.f_bsize;
        unsigned long long required_disk_size = 2 * (33 * 512) + all_partitions_size;
        if (disk_size < required_disk_size) {
            gErrorLines.push_back("Boot disk " + BOOT_DISK_NAME + " is too small (" +
                                  std::to_string(disk_size) + " < " +
                                  std::to_string(required_disk_size) + ")");
        }
    } else {
        LOG(ERROR) << "Failed to statvfs() for " << disk_path;
    }
}

void checkRamSize() {
    struct sysinfo sys;
    sysinfo(&sys);
    if (sys.totalram < MB(1280)) {
        gErrorLines.push_back("RAM is too small. Minimum recommended RAM size is 2 GiB.");
    }
}

void checkSharedMemory() {
    int fd = ashmem_create_region("test_region", 4096);
    if (fd < 0) {
        gErrorLines.push_back(
                "Failed to call ashmem_create_region(). Shared memory is likely not enabled.");
        return;
    }
    close(fd);
}

void checkUserdataDisk() {
    // Check whether if the disk is accessible
    std::string disk_path = "/dev/block/" + USERDATA_DISK_NAME;
    int disk_fd = open(disk_path.c_str(), O_RDONLY);
    if (disk_fd < 0) {
        gErrorLines.push_back("Failed to open userdata disk " + USERDATA_DISK_NAME +
                              ". Is the disk not created yet or attached to different bus?");
        return;
    }
    close(disk_fd);

    // Check disk size
    struct statvfs disk_stat;
    if (statvfs(disk_path.c_str(), &disk_stat) == 0) {
        unsigned long long disk_size = disk_stat.f_blocks * disk_stat.f_bsize;
        if (disk_size < GB(1)) {
            gErrorLines.push_back("Userdata disk " + USERDATA_DISK_NAME +
                                  " is too small. Minimum recommended size is 2 GiB.");
        }
    } else {
        LOG(ERROR) << "Failed to statvfs() for " << disk_path;
    }

    // Userdata disk should not contain any partition
    int test_fd = open("/dev/block/" USERDATA_DISK_NAME "1", O_RDONLY);
    if (test_fd > 0) {
        gErrorLines("Userdata disk " + USERDATA_DISK_NAME +
                    " should not contain partition(s). Are the disks in incorrect order?");
        close(test_fd);
    }
}

void checkVideo() {
    int fd = open("/dev/dri/card0", O_RDWR);
    if (fd < 0) {
        gErrorLines.push_back(
                "Failed to open the first DRM card. Please add a supported video card.");
        return;
    }

    drmVersionPtr drm_version = drmGetVersion(fd);
    if (!drm_version) {
        LOG(ERROR) << "drmGetVersion() failed.";
        close(fd);
        return;
    }

    if (strcmp(drm_version->name, DRM_CARD_NAME)) {
        gErrorLines.push_back(
                "Failed to match DRM card name with the first DRM card. Please use a supported "
                "video card and make it default.");
    }

    drmFreeVersion(drm_version);
    close(fd);
}

int main(int argc __unused, char** argv) {
    android::base::InitLogging(argv, &android::base::KernelLogger);

    checkBootDiskPartitions();
    checkCpuFlags();
    checkRamSize();
    checkSharedMemory();
    checkUserdataDisk();
    checkVideo();

    if (gErrorLines.empty()) {
        LOG(INFO) << "Found no errors.";
        SetProperty("vendor.preinstall_check.success", "1");
        return EXIT_SUCCESS;
    }

    LOG(ERROR) << kErrorIcon;
    LOG(ERROR) << "Could not continue installation due to the following errors:";
    for (int i = 1; i <= gErrorLines.size(); i++) {
        LOG(ERROR) << std::to_string(i) << ". " << line;
    }
    LOG(ERROR) << "Please shut down this virtual machine and fix these errors.";

    return EXIT_FAILURE;
}

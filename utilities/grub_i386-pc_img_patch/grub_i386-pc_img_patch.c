#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#define GRUB_BOOT_MACHINE_KERNEL_SECTOR 0x5C
#define GRUB_BOOT_MACHINE_DRIVE_CHECK   0x66

#define BOOTSTRAP_CODE_SIZE 446
#define CORE_IMG_PAYLOAD_START_SECTOR_OFFSET 0x1F4

typedef uint32_t grub_uint32_t;

void grub_uint32_to_little_endian(grub_uint32_t value, unsigned char *buffer) {
    buffer[0] = (unsigned char)(value & 0xFF);
    buffer[1] = (unsigned char)((value >> 8) & 0xFF);
    buffer[2] = (unsigned char)((value >> 16) & 0xFF);
    buffer[3] = (unsigned char)((value >> 24) & 0xFF);
}

int main(int argc, char *argv[]) {
    unsigned char bootstrap_code[BOOTSTRAP_CODE_SIZE];
    unsigned char grub_uint32_buf[4];
    grub_uint32_t bios_boot_partition_start_sector = 0;
    char *boot_img_path, *core_img_path;
    int boot_img_fd, core_img_fd;

    if (argc != 4) {
        fprintf(stderr, "Usage: %s <bios_boot_partition_start_sector> <boot.img path> <core.img path>\n", argv[0]);
        return EXIT_FAILURE;
    }

    bios_boot_partition_start_sector = atoi(argv[1]);
    boot_img_path = argv[2];
    core_img_path = argv[3];

    // Read Bootstrap code from boot.img file
    boot_img_fd = open(boot_img_path, O_RDWR);
    if (boot_img_fd < 0) {
        perror("Error opening boot.img");
        return EXIT_FAILURE;
    }

    if (read(boot_img_fd, bootstrap_code, BOOTSTRAP_CODE_SIZE) != BOOTSTRAP_CODE_SIZE) {
        perror("Error reading boot.img");
        close(boot_img_fd);
        return EXIT_FAILURE;
    }

    // Modify Bootstrap code in memory
    grub_uint32_to_little_endian(bios_boot_partition_start_sector, grub_uint32_buf);
    memcpy(bootstrap_code + GRUB_BOOT_MACHINE_KERNEL_SECTOR, grub_uint32_buf, sizeof(grub_uint32_buf));
    bootstrap_code[GRUB_BOOT_MACHINE_DRIVE_CHECK] = 0x90;
    bootstrap_code[GRUB_BOOT_MACHINE_DRIVE_CHECK + 1] = 0x90;

    // Write modified Bootstrap code to boot.img file
    if (lseek(boot_img_fd, 0, SEEK_SET) < 0) {
        perror("Error seeking to start of boot.img");
        close(boot_img_fd);
        return EXIT_FAILURE;
    }

    if (write(boot_img_fd, bootstrap_code, BOOTSTRAP_CODE_SIZE) != BOOTSTRAP_CODE_SIZE) {
        perror("Error writing to boot.img");
        close(boot_img_fd);
        return EXIT_FAILURE;
    }

    close(boot_img_fd);

    // Modify core.img file
    core_img_fd = open(core_img_path, O_RDWR);
    if (core_img_fd < 0) {
        perror("Error opening core.img");
        return EXIT_FAILURE;
    }

    grub_uint32_to_little_endian(bios_boot_partition_start_sector + 1, grub_uint32_buf);

    if (lseek(core_img_fd, CORE_IMG_PAYLOAD_START_SECTOR_OFFSET, SEEK_SET) < 0) {
        perror("Error seeking to core.img offset");
        close(core_img_fd);
        return EXIT_FAILURE;
    }

    if (write(core_img_fd, grub_uint32_buf, sizeof(grub_uint32_buf)) != sizeof(grub_uint32_buf)) {
        perror("Error writing to core.img offset");
        close(core_img_fd);
        return EXIT_FAILURE;
    }

    close(core_img_fd);

    printf("boot.img and core.img updated.\n");
    return EXIT_SUCCESS;
}

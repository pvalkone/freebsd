/*
 * Turns all relays off and then on on a USB-RLY02.
 *
 * Based on: http://www.robot-electronics.co.uk/files/linux_rly02.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/types.h>

void usage() {
    fprintf(stderr, "usage: %s device\n", getprogname());
    exit(EXIT_FAILURE);
}

void print_error_and_exit(char *message) {
    perror(message);
    exit(EXIT_FAILURE);
}

void write_to_device(int fd, int command) {
    char sbuf[2];
    sbuf[0] = command;
    if (write(fd, sbuf, 1) < 0) {
        print_error_and_exit("Error while writing output");
    }
    if (tcdrain(fd) < 0) {
        print_error_and_exit("Error while waiting for output to be transmitted");
    }
}

int main(int argc, char *argv[]) {
    struct termios defaults;
    struct termios config;
    if (argc != 2) {
        usage();
    }
    const char *device = argv[optind];
    int fd = open(device, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1) {
        char *message = malloc(22 + strlen(device) + 1);
        sprintf(message, "Failed to open device %s", device);
        print_error_and_exit(message);
    }
    if (tcgetattr(fd, &defaults) < 0) {
        print_error_and_exit("Failed to read port defaults");
    }
    cfmakeraw(&config);
    if (tcsetattr(fd, TCSANOW, &config) < 0) {
        print_error_and_exit("Failed to configure port");
    }
    write_to_device(fd, 0x6E); // Turn all relays off
    sleep(3);
    write_to_device(fd, 0x64); // Turn all relays on
    if (tcsetattr(fd, TCSANOW, &defaults) < 0) {
        print_error_and_exit("Failed to restore port defaults");
    }
    close(fd);
    return EXIT_SUCCESS;
}

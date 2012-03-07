/*
 * Toggles all relays off and on on a USB-RLY02.
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

void write_to_device(int fd, int command) {
    char sbuf[2];
    sbuf[0] = command;
    if (write(fd, sbuf, 1) < 0) perror("Error writing output\n");
    if (tcdrain(fd) < 0) perror("Error while waiting for output to be transmitted\n");
}

int main(int argc, char *argv[]) {    struct termios defaults;
    struct termios config;
    const char *device = "/dev/cuaU1";
    int fd = open(device, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1) {
        printf( "Failed to open port\n" );
    } else {
        if (tcgetattr(fd, &defaults) < 0) perror("Failed to read port defaults\n");
        cfmakeraw(&config);
        if (tcsetattr(fd, TCSANOW, &config) < 0) perror("Failed to configure port\n");
        write_to_device(fd, 0x6E); // Turn all relays off
        sleep(3);
        write_to_device(fd, 0x64); // Turn all relays on
        if (tcsetattr(fd, TCSANOW, &defaults) < 0) perror("Failed to restore port defaults\n");
        close(fd);
    }
    return(0);
}

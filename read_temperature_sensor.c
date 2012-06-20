/*
 * Read temperature data from a LM335 sensor attached to an Arduino
 * Duemilanove microcontroller board. Since the controller outputs the
 * data as a moving average of the last 10 measurements, only the 11th
 * value is output.
 *
 * The format of the input data is:
 *
 * YYYY.MM.DD,HH:MM:SS,temperature in degrees Celcius (one decimal place)
 *
 * For example:
 *
 * 2012.06.19,20:47:00,2.9
 * 2012.06.19,20:47:01,6.0
 * 2012.06.19,20:47:02,9.1
 * 2012.06.19,20:47:03,12.2
 * 2012.06.19,20:47:04,15.3
 * 2012.06.19,20:47:05,18.4
 * 2012.06.19,20:47:06,21.5
 * 2012.06.19,20:47:07,24.5
 * 2012.06.19,20:47:08,27.6
 * 2012.06.19,20:47:09,30.7
 * 2012.06.19,20:47:10,33.8
 */
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SAMPLE_COUNT 11
#define TEMPERATURE_TOKEN_INDEX 3
#define FIELD_DELIMITER ","

void usage() {
    fprintf(stderr, "usage: %s device\n", getprogname());
    exit(EXIT_FAILURE);
}

char *get_token(char *str, int count, char *delim) {
    int i = 0;
    char *token = strtok(str, delim);
    while (token != NULL) {
        if (i == count - 1) {
            return token;
        }
        token = strtok(NULL, delim);
        i++;
    }
    return token;
}

double read_temperature(int fd, int count) {
    double temp = INT_MIN;
    int i = 0;
    while (i < count) {
        char buf[255];
        if (read(fd, buf, sizeof(buf)) && *buf != '\n') {
            char *temp_str = get_token(buf, TEMPERATURE_TOKEN_INDEX,
                                       FIELD_DELIMITER);
            if (temp_str != NULL) {
                temp = strtod(temp_str, NULL);
                i++;
            }
        }
    }
    return temp;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        usage();
    }
    const char *device = argv[optind++];
    int fd = open(device, O_RDONLY | O_NOCTTY);
    if (fd == -1) {
        char *message;
        asprintf(&message, "Failed to open device %s", device);
        perror(message);
        exit(EXIT_FAILURE);
    }
    printf("%.1f\n", read_temperature(fd, SAMPLE_COUNT));
    close(fd);
    return EXIT_SUCCESS;
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <math.h>

#define MAX_GAMMA 65535
#define GAMMA_SIZE 256
#define MIN_GAMMA 0.0
#define MAX_GAMMA_VALUE 2.0

void print_usage(const char* program_name) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  Single value:  %s -s <gamma>\n", program_name);
    fprintf(stderr, "  RGB values:    %s -r <red> -g <green> -b <blue>\n", program_name);
    fprintf(stderr, "  Custom table:  %s -t <file>\n", program_name);
    fprintf(stderr, "Values should be between %.1f and %.1f\n", MIN_GAMMA, MAX_GAMMA_VALUE);
}

// Validate gamma value
int validate_gamma(float gamma, const char* channel_name) {
    if (gamma < MIN_GAMMA || gamma > MAX_GAMMA_VALUE || isnan(gamma)) {
        fprintf(stderr, "Invalid %s gamma value: %.2f (must be between %.1f and %.1f)\n",
                channel_name, gamma, MIN_GAMMA, MAX_GAMMA_VALUE);
        return 0;
    }
    return 1;
}

// Convert float gamma value to lookup table
void generate_gamma_table(float gamma, uint16_t* table, int size) {
    if (gamma == 0.0) {
        // Special case: all black
        memset(table, 0, size * sizeof(uint16_t));
        return;
    }
    
    for (int i = 0; i < size; i++) {
        double value = (double)i / (size - 1);
        double corrected = pow(value, 1.0 / gamma);
        // Clamp values to prevent overflow
        if (corrected > 1.0) corrected = 1.0;
        if (corrected < 0.0) corrected = 0.0;
        table[i] = (uint16_t)(corrected * MAX_GAMMA + 0.5);
    }
}

// Clean up resources
void cleanup(int fd, drmModeRes *resources, uint16_t *red, uint16_t *green, uint16_t *blue) {
    if (red) free(red);
    if (green) free(green);
    if (blue) free(blue);
    if (resources) drmModeFreeResources(resources);
    if (fd >= 0) close(fd);
}

int main(int argc, char *argv[]) {
    int fd = -1, i, opt;
    uint32_t crtc_id = 0;
    drmModeCrtc *crtc = NULL;
    drmModeRes *resources = NULL;
    float gamma_r = 1.0, gamma_g = 1.0, gamma_b = 1.0;
    uint16_t *red_table = NULL, *green_table = NULL, *blue_table = NULL;
    char mode = 0;
    char *filename = NULL;
    int rgb_flags = 0;  // Bit flags for RGB parameters

    // Parse command line arguments
    while ((opt = getopt(argc, argv, "s:r:g:b:t:h")) != -1) {
        switch (opt) {
            case 's':
                if (mode != 0) {
                    fprintf(stderr, "Error: Cannot combine different gamma modes\n");
                    print_usage(argv[0]);
                    return 1;
                }
                mode = 's';
                gamma_r = gamma_g = gamma_b = atof(optarg);
                break;
            case 'r':
                mode = 'c';
                gamma_r = atof(optarg);
                rgb_flags |= 1;
                break;
            case 'g':
                mode = 'c';
                gamma_g = atof(optarg);
                rgb_flags |= 2;
                break;
            case 'b':
                mode = 'c';
                gamma_b = atof(optarg);
                rgb_flags |= 4;
                break;
            case 't':
                if (mode != 0) {
                    fprintf(stderr, "Error: Cannot combine different gamma modes\n");
                    print_usage(argv[0]);
                    return 1;
                }
                mode = 't';
                filename = optarg;
                break;
            case 'h':
            default:
                print_usage(argv[0]);
                return 1;
        }
    }

    // Validate input parameters
    if (mode == 0) {
        fprintf(stderr, "Error: No gamma mode specified\n");
        print_usage(argv[0]);
        return 1;
    }

    if (mode == 'c' && rgb_flags != 7) {
        fprintf(stderr, "Error: When using RGB mode, all three values (r,g,b) must be specified\n");
        print_usage(argv[0]);
        return 1;
    }

    // Validate gamma values
    if (mode == 's' || mode == 'c') {
        if (!validate_gamma(gamma_r, "red") ||
            !validate_gamma(gamma_g, "green") ||
            !validate_gamma(gamma_b, "blue")) {
            return 1;
        }
    }

    // Open DRM device
    fd = open("/dev/dri/card0", O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "Failed to open DRM device: %s\n", strerror(errno));
        return 1;
    }

    // Get DRM resources
    resources = drmModeGetResources(fd);
    if (!resources) {
        fprintf(stderr, "Failed to get DRM resources: %s\n", strerror(errno));
        cleanup(fd, resources, NULL, NULL, NULL);
        return 1;
    }

    // Verify we have at least one CRTC
    if (resources->count_crtcs <= 0) {
        fprintf(stderr, "No CRTCs found\n");
        cleanup(fd, resources, NULL, NULL, NULL);
        return 1;
    }

    // Use the first CRTC
    crtc_id = resources->crtcs[0];

    // Allocate gamma tables
    red_table = calloc(GAMMA_SIZE, sizeof(uint16_t));
    green_table = calloc(GAMMA_SIZE, sizeof(uint16_t));
    blue_table = calloc(GAMMA_SIZE, sizeof(uint16_t));

    if (!red_table || !green_table || !blue_table) {
        fprintf(stderr, "Failed to allocate memory: %s\n", strerror(errno));
        cleanup(fd, resources, red_table, green_table, blue_table);
        return 1;
    }

    // Fill gamma tables based on mode
    if (mode == 's' || mode == 'c') {
        generate_gamma_table(gamma_r, red_table, GAMMA_SIZE);
        generate_gamma_table(gamma_g, green_table, GAMMA_SIZE);
        generate_gamma_table(gamma_b, blue_table, GAMMA_SIZE);
    } else if (mode == 't') {
        FILE *f = fopen(filename, "r");
        if (!f) {
            fprintf(stderr, "Failed to open gamma table file '%s': %s\n", 
                    filename, strerror(errno));
            cleanup(fd, resources, red_table, green_table, blue_table);
            return 1;
        }

        for (i = 0; i < GAMMA_SIZE; i++) {
            float r, g, b;
            if (fscanf(f, "%f %f %f", &r, &g, &b) != 3) {
                fprintf(stderr, "Invalid gamma table format at line %d\n", i + 1);
                fclose(f);
                cleanup(fd, resources, red_table, green_table, blue_table);
                return 1;
            }
            
            // Validate table values
            if (r < 0.0 || r > 1.0 || g < 0.0 || g > 1.0 || b < 0.0 || b > 1.0) {
                fprintf(stderr, "Invalid gamma table values at line %d (must be between 0.0 and 1.0)\n", i + 1);
                fclose(f);
                cleanup(fd, resources, red_table, green_table, blue_table);
                return 1;
            }

            red_table[i] = (uint16_t)(r * MAX_GAMMA);
            green_table[i] = (uint16_t)(g * MAX_GAMMA);
            blue_table[i] = (uint16_t)(b * MAX_GAMMA);
        }
        fclose(f);
    }

    // Set gamma
    if (drmModeCrtcSetGamma(fd, crtc_id, GAMMA_SIZE, red_table, green_table, blue_table) != 0) {
        fprintf(stderr, "Failed to set gamma: %s\n", strerror(errno));
        cleanup(fd, resources, red_table, green_table, blue_table);
        return 1;
    }

    // Cleanup
    cleanup(fd, resources, red_table, green_table, blue_table);

    printf("Gamma settings applied successfully\n");
    return 0;
}

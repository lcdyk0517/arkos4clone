#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <math.h>
#include <getopt.h>
#include <sys/stat.h>

#define STATE_FILE "/dev/shm/CURRENT_GAMMA"
#define CONFIG_DIR ".config/gamma"
#define CONFIG_FILE ".config/gamma/GAMMA.VALUE"
#define DEFAULT_GAMMA 1.0f
#define MIN_GAMMA 0.3f
#define MAX_GAMMA 2.0f
#define MAX_GAMMA_16BIT 65535

// 读取状态文件：尝试读取三个值（R,G,B），若失败则回退到单一值
void read_current_gamma_from_file(float *r, float *g, float *b) {
    FILE *fp = fopen(STATE_FILE, "r");
    if (!fp) {
        *r = *g = *b = DEFAULT_GAMMA;
        return;
    }
    int n = fscanf(fp, "%f %f %f", r, g, b);
    fclose(fp);
    if (n == 3) {
        // 钳位
        if (*r < MIN_GAMMA) *r = MIN_GAMMA;
        if (*r > MAX_GAMMA) *r = MAX_GAMMA;
        if (*g < MIN_GAMMA) *g = MIN_GAMMA;
        if (*g > MAX_GAMMA) *g = MAX_GAMMA;
        if (*b < MIN_GAMMA) *b = MIN_GAMMA;
        if (*b > MAX_GAMMA) *b = MAX_GAMMA;
    } else {
        // 回退：只读一个数
        float val;
        fp = fopen(STATE_FILE, "r");
        if (!fp) {
            *r = *g = *b = DEFAULT_GAMMA;
            return;
        }
        if (fscanf(fp, "%f", &val) != 1) val = DEFAULT_GAMMA;
        fclose(fp);
        if (val < MIN_GAMMA) val = MIN_GAMMA;
        if (val > MAX_GAMMA) val = MAX_GAMMA;
        *r = *g = *b = val;
    }
}

void save_current_gamma_rgb(float r, float g, float b) {
    if (r < MIN_GAMMA) r = MIN_GAMMA;
    if (r > MAX_GAMMA) r = MAX_GAMMA;
    if (g < MIN_GAMMA) g = MIN_GAMMA;
    if (g > MAX_GAMMA) g = MAX_GAMMA;
    if (b < MIN_GAMMA) b = MIN_GAMMA;
    if (b > MAX_GAMMA) b = MAX_GAMMA;

    // Save to /dev/shm (runtime)
    FILE *fp = fopen(STATE_FILE, "w");
    if (fp) {
        fprintf(fp, "%.2f %.2f %.2f\n", r, g, b);
        fclose(fp);
    }

    // Save to ~/.config/gamma/GAMMA.VALUE (persistent)
    char config_path[512];
    const char *home = getenv("HOME");
    if (home) {
        snprintf(config_path, sizeof(config_path), "%s/%s", home, CONFIG_FILE);
        char dir_path[512];
        snprintf(dir_path, sizeof(dir_path), "%s/%s", home, CONFIG_DIR);
        mkdir(dir_path, 0755);
        fp = fopen(config_path, "w");
        if (fp) {
            fprintf(fp, "%.2f %.2f %.2f\n", r, g, b);
            fclose(fp);
        }
    }
}

void print_usage(const char* program_name) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  Query current hardware: %s\n", program_name);
    fprintf(stderr, "  Increment:              %s +0.1\n", program_name);
    fprintf(stderr, "  Decrement:              %s -0.1\n", program_name);
    fprintf(stderr, "  Reset to 1.0:           %s -R\n", program_name);
    fprintf(stderr, "  Set single value:       %s -s <gamma>\n", program_name);
    fprintf(stderr, "  Set RGB values:         %s -r <red> -g <green> -b <blue>\n", program_name);
    fprintf(stderr, "Values must be between %.1f and %.1f\n", MIN_GAMMA, MAX_GAMMA);
}

int validate_gamma(float gamma, const char* channel_name) {
    if (gamma < MIN_GAMMA || gamma > MAX_GAMMA || isnan(gamma)) {
        fprintf(stderr, "Invalid %s gamma value: %.2f (must be between %.1f and %.1f)\n",
                channel_name, gamma, MIN_GAMMA, MAX_GAMMA);
        return 0;
    }
    return 1;
}

void generate_gamma_table(float gamma, uint16_t* table, int size) {
    for (int i = 0; i < size; i++) {
        double value = (double)i / (size - 1);
        double corrected = pow(value, 1.0 / gamma);
        if (corrected > 1.0) corrected = 1.0;
        if (corrected < 0.0) corrected = 0.0;
        table[i] = (uint16_t)(corrected * MAX_GAMMA_16BIT + 0.5);
    }
}

void cleanup(int fd, drmModeRes *resources, drmModeCrtc *crtc,
             uint16_t *red, uint16_t *green, uint16_t *blue) {
    if (red) free(red);
    if (green) free(green);
    if (blue) free(blue);
    if (crtc) drmModeFreeCrtc(crtc);
    if (resources) drmModeFreeResources(resources);
    if (fd >= 0) close(fd);
}

int main(int argc, char *argv[]) {
    int fd = -1;
    uint32_t crtc_id = 0;
    drmModeRes *resources = NULL;
    drmModeCrtc *crtc = NULL;
    float gamma_r = 1.0f, gamma_g = 1.0f, gamma_b = 1.0f;
    uint16_t *red_table = NULL, *green_table = NULL, *blue_table = NULL;
    int gamma_size = 0;
    char mode = 0;          // 's' = single, 'c' = color
    int rgb_flags = 0;
    int opt;

    // ===== 处理无参数（查询硬件当前值） =====
    if (argc == 1) {
        // 打开设备并获取资源
        fd = open("/dev/dri/card0", O_RDWR);
        if (fd < 0) {
            fprintf(stderr, "Failed to open DRM device: %s\n", strerror(errno));
            return 1;
        }
        resources = drmModeGetResources(fd);
        if (!resources) {
            fprintf(stderr, "Failed to get DRM resources\n");
            close(fd);
            return 1;
        }
        if (resources->count_crtcs == 0) {
            fprintf(stderr, "No CRTCs\n");
            drmModeFreeResources(resources);
            close(fd);
            return 1;
        }
        // 找第一个活动的连接器对应的 CRTC
        int found = 0;
        for (int i = 0; i < resources->count_connectors; i++) {
            drmModeConnector *conn = drmModeGetConnector(fd, resources->connectors[i]);
            if (!conn) continue;
        if (conn->connection == DRM_MODE_CONNECTED && conn->count_modes > 0 && conn->encoder_id != 0) {
            drmModeEncoder *enc = drmModeGetEncoder(fd, conn->encoder_id);
            if (enc && enc->crtc_id != 0) {
                crtc_id = enc->crtc_id;
                found = 1;
                drmModeFreeEncoder(enc);
                drmModeFreeConnector(conn);
                break;
            }
            if (enc) drmModeFreeEncoder(enc);
        }
        drmModeFreeConnector(conn);
    }
    if (!found) {
        // 保底用第一个
        crtc_id = resources->crtcs[0];
    }

    crtc = drmModeGetCrtc(fd, crtc_id);
    if (!crtc) {
        fprintf(stderr, "Failed to get CRTC info\n");
        cleanup(fd, resources, NULL, NULL, NULL, NULL);
        return 1;
    }
    gamma_size = crtc->gamma_size;
        if (gamma_size <= 0) gamma_size = 256;

        // 分配内存并读取硬件 gamma 表
        red_table = calloc(gamma_size, sizeof(uint16_t));
        green_table = calloc(gamma_size, sizeof(uint16_t));
        blue_table = calloc(gamma_size, sizeof(uint16_t));
        if (!red_table || !green_table || !blue_table) {
            fprintf(stderr, "Memory allocation failed\n");
            cleanup(fd, resources, crtc, red_table, green_table, blue_table);
            return 1;
        }

        if (drmModeCrtcGetGamma(fd, crtc_id, gamma_size, red_table, green_table, blue_table) != 0) {
            fprintf(stderr, "Failed to read gamma: %s\n", strerror(errno));
            cleanup(fd, resources, crtc, red_table, green_table, blue_table);
            return 1;
        }

        // 从表中提取中间点的值（代表等效 gamma）
        int mid = gamma_size / 2;
        double r = red_table[mid] / (double)MAX_GAMMA_16BIT;
        double g = green_table[mid] / (double)MAX_GAMMA_16BIT;
        double b = blue_table[mid] / (double)MAX_GAMMA_16BIT;
        // 反推等效 gamma：gamma = log(0.5) / log(value) ，但 value 为 0.5 时 gamma=1
        // 简单方法：直接显示三个通道在中间点的归一化值，并计算平均值。
        double avg = (r + g + b) / 3.0;
        // 为了更直观，我们可以拟合 gamma，但直接显示归一化值更透明。
        printf("Hardware gamma table (%d entries) at 50%% input:\n", gamma_size);
        printf("  R=%.3f  G=%.3f  B=%.3f\n", r, g, b);
        printf("  Equivalent average gamma ≈ %.2f\n", 1.0 / (log(avg) / log(0.5))); // 仅当 avg>0
        // 与状态文件对比
        float fr, fg, fb;
        read_current_gamma_from_file(&fr, &fg, &fb);
        printf("State file: R=%.2f G=%.2f B=%.2f\n", fr, fg, fb);

        cleanup(fd, resources, crtc, red_table, green_table, blue_table);
        return 0;
    }

    // ===== 处理单参数特殊指令（重置、增量） =====
    if (argc == 2) {
        char *arg = argv[1];
        if (strcmp(arg, "-R") == 0 || strcmp(arg, "--reset") == 0) {
            gamma_r = gamma_g = gamma_b = 1.0f;
            mode = 's';
            save_current_gamma_rgb(1.0f, 1.0f, 1.0f);
            printf("Gamma reset to 1.0 (will apply after DRM setup)\n");
            // 继续执行后面的应用逻辑
            goto apply_gamma;
        }
        if ((arg[0] == '+' || arg[0] == '-') && strlen(arg) > 1) {
            float delta = atof(arg);
            float cur_r, cur_g, cur_b;
            read_current_gamma_from_file(&cur_r, &cur_g, &cur_b);
            float avg = (cur_r + cur_g + cur_b) / 3.0f;
            float new_val = avg + delta;
            if (new_val < MIN_GAMMA) new_val = MIN_GAMMA;
            if (new_val > MAX_GAMMA) new_val = MAX_GAMMA;
            float ratio = new_val / avg;
            gamma_r = cur_r * ratio;
            gamma_g = cur_g * ratio;
            gamma_b = cur_b * ratio;
            if (gamma_r < MIN_GAMMA) gamma_r = MIN_GAMMA;
            if (gamma_r > MAX_GAMMA) gamma_r = MAX_GAMMA;
            if (gamma_g < MIN_GAMMA) gamma_g = MIN_GAMMA;
            if (gamma_g > MAX_GAMMA) gamma_g = MAX_GAMMA;
            if (gamma_b < MIN_GAMMA) gamma_b = MIN_GAMMA;
            if (gamma_b > MAX_GAMMA) gamma_b = MAX_GAMMA;
            mode = 'c';
            save_current_gamma_rgb(gamma_r, gamma_g, gamma_b);
            printf("Incremented: R=%.2f G=%.2f B=%.2f (delta %.2f)\n",
                   gamma_r, gamma_g, gamma_b, delta);
            goto apply_gamma;
        }
        // 其他情况（如 -r 单独出现）会进入 getopt，后面报错
    }

    // ===== getopt 解析 =====
    optind = 1;
    while ((opt = getopt(argc, argv, "s:r:g:b:")) != -1) {
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
            default:
                fprintf(stderr, "Unknown option or missing argument\n");
                print_usage(argv[0]);
                return 1;
        }
    }

    // ===== 参数校验 =====
    if (mode == 0) {
        fprintf(stderr, "Error: No valid mode specified\n");
        print_usage(argv[0]);
        return 1;
    }
    if (mode == 'c' && rgb_flags != 7) {
        fprintf(stderr, "Error: When using RGB mode, all three values (r,g,b) must be specified\n");
        print_usage(argv[0]);
        return 1;
    }
    if (mode == 's' || mode == 'c') {
        if (!validate_gamma(gamma_r, "red") ||
            !validate_gamma(gamma_g, "green") ||
            !validate_gamma(gamma_b, "blue")) {
            return 1;
        }
    }

apply_gamma:
    // ===== 打开 DRM 设备并应用 =====
    fd = open("/dev/dri/card0", O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "Failed to open DRM device: %s\n", strerror(errno));
        return 1;
    }

    resources = drmModeGetResources(fd);
    if (!resources) {
        fprintf(stderr, "Failed to get DRM resources\n");
        close(fd);
        return 1;
    }
    if (resources->count_crtcs == 0) {
        fprintf(stderr, "No CRTCs\n");
        drmModeFreeResources(resources);
        close(fd);
        return 1;
    }

    // 找活动的连接器对应的 CRTC
    int found = 0;
    for (int i = 0; i < resources->count_connectors; i++) {
        drmModeConnector *conn = drmModeGetConnector(fd, resources->connectors[i]);
        if (!conn) continue;
            if (conn->connection == DRM_MODE_CONNECTED && conn->count_modes > 0 && conn->encoder_id != 0) {
                drmModeEncoder *enc = drmModeGetEncoder(fd, conn->encoder_id);
                if (enc && enc->crtc_id != 0) {
                    crtc_id = enc->crtc_id;
                    found = 1;
                    drmModeFreeEncoder(enc);
                    drmModeFreeConnector(conn);
                    break;
                }
                if (enc) drmModeFreeEncoder(enc);
            }
        drmModeFreeConnector(conn);
    }
    if (!found) {
        crtc_id = resources->crtcs[0];
    }

    crtc = drmModeGetCrtc(fd, crtc_id);
    if (!crtc) {
        fprintf(stderr, "Failed to get CRTC info\n");
        cleanup(fd, resources, NULL, NULL, NULL, NULL);
        return 1;
    }
    gamma_size = crtc->gamma_size;
    if (gamma_size <= 0) gamma_size = 256;

    red_table = calloc(gamma_size, sizeof(uint16_t));
    green_table = calloc(gamma_size, sizeof(uint16_t));
    blue_table = calloc(gamma_size, sizeof(uint16_t));
    if (!red_table || !green_table || !blue_table) {
        fprintf(stderr, "Memory allocation failed\n");
        cleanup(fd, resources, crtc, red_table, green_table, blue_table);
        return 1;
    }

    if (mode == 's' || mode == 'c') {
        generate_gamma_table(gamma_r, red_table, gamma_size);
        generate_gamma_table(gamma_g, green_table, gamma_size);
        generate_gamma_table(gamma_b, blue_table, gamma_size);
    }

    if (drmModeCrtcSetGamma(fd, crtc_id, gamma_size, red_table, green_table, blue_table) != 0) {
        fprintf(stderr, "Failed to set gamma: %s\n", strerror(errno));
        cleanup(fd, resources, crtc, red_table, green_table, blue_table);
        return 1;
    }

    // 如果是 -s/-c 模式，保存状态文件
    if (mode == 's' || mode == 'c') {
        save_current_gamma_rgb(gamma_r, gamma_g, gamma_b);
    }

    printf("Gamma applied successfully\n");

    cleanup(fd, resources, crtc, red_table, green_table, blue_table);
    return 0;
}
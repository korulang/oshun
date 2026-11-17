// koruos host shim — darwin development provider for the koru-native
// canvas part's extern ABI (index.koru-native.kz). NOT the kernel: a
// bounded host stand-in so --build=koru-native programs link and run on
// macOS. Surface = malloc'd w*h*4 backing (0x00RRGGBB, bottom-up rows
// like the kernel's surf.zig convention is TOP-DOWN? — see note below);
// present() accumulates damage; close() dumps /tmp/kn_surface.bmp.
// koru_wire bytes append to /tmp/kn_wire.bin. Input verbs are inert
// (no pump on host). koru_glyph8 returns 0 — bitmap text is a named
// koru-native delta, not shimmed here.
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

typedef struct { uint32_t x, y, w, h, sw, sh; } Geom;
typedef struct Surf {
    uint32_t w, h;
    uint32_t *px;      // w*h pixels, 0x00RRGGBB
    int dirty;
    char tag[64];
} Surf;

static Surf *g_last = NULL;

void *koruos_surface_open(uint32_t w, uint32_t h, const char *title) {
    (void)title;
    Surf *s = calloc(1, sizeof(Surf));
    if (!s) return NULL;
    s->w = w; s->h = h;
    if (title) { strncpy(s->tag, title, sizeof(s->tag) - 1); s->tag[sizeof(s->tag)-1] = 0; }
    else snprintf(s->tag, sizeof s->tag, "%ux%u", w, h);
    s->px = calloc((size_t)w * h, 4);
    if (!s->px) { free(s); return NULL; }
    g_last = s;
    return s;
}

uint8_t koruos_surface_present(void *p, uint32_t x, uint32_t y, uint32_t w, uint32_t h) {
    (void)p; (void)x; (void)y; (void)w; (void)h;
    if (g_last) g_last->dirty = 1;
    return 0;
}

uint8_t koruos_surface_close(void *p) {
    Surf *s = (Surf *)p;
    if (s && s->dirty) {
        // dump 32-bit BMP (top-down negative height), 0x00RRGGBB -> BGRX
        char path[256];
        const char *env = getenv("KN_TAG");
        snprintf(path, sizeof path, "/tmp/kn_surface_%s.bmp", env ? env : s->tag);
        FILE *fp = fopen(path, "wb");
        if (fp) {
            uint32_t row = ((s->w * 4 + 3) / 4) * 4;
            uint32_t img = row * s->h;
            uint32_t off = 54;
            uint8_t hdr[54] = {0};
            hdr[0]='B'; hdr[1]='M';
            *(uint32_t*)(hdr+2) = off + img;
            *(uint32_t*)(hdr+10) = off;
            *(uint32_t*)(hdr+14) = 40;
            *(int32_t*)(hdr+18) = (int32_t)s->w;
            *(int32_t*)(hdr+22) = -(int32_t)s->h; // top-down
            *(uint16_t*)(hdr+26) = 1;
            *(uint16_t*)(hdr+28) = 32;
            *(uint32_t*)(hdr+34) = img;
            fwrite(hdr, 1, 54, fp);
            uint8_t *line = malloc(row);
            for (uint32_t yy = 0; yy < s->h; yy++) {
                memset(line, 0, row);
                for (uint32_t xx = 0; xx < s->w; xx++) {
                    uint32_t px = s->px[yy * s->w + xx];
                    line[xx*4+0] = px & 0xFF;          // B
                    line[xx*4+1] = (px >> 8) & 0xFF;   // G
                    line[xx*4+2] = (px >> 16) & 0xFF;  // R
                    line[xx*4+3] = 0;
                }
                fwrite(line, 1, row, fp);
            }
            free(line);
            fclose(fp);
        }
    }
    if (s) { free(s->px); free(s); }
    if (g_last == s) g_last = NULL;
    return 0;
}

uint8_t koruos_surface_map(void *p, uint64_t *out_phys, uint64_t *out_bytes) {
    Surf *s = (Surf *)p;
    if (!s || !s->px) return 1;
    *out_phys = (uint64_t)(uintptr_t)s->px;
    *out_bytes = (uint64_t)s->w * s->h * 4;
    return 1; // map: nonzero = mapped (call site fails on ==0)
}

uint8_t koruos_surface_geom(void *p, Geom *out) {
    Surf *s = (Surf *)p;
    if (!s) return 1;
    out->x = 0; out->y = 0; out->w = s->w; out->h = s->h;
    out->sw = s->w; out->sh = s->h;
    return 0;
}

void koru_tick(void) {}
int32_t koru_kbd_poll(void) { return -1; } // <0 = queue empty (pollInput breaks on c<0)
void koru_pointer_state(int32_t *x, int32_t *y, uint8_t *on, uint32_t *buttons) {
    if (x) *x = 0; if (y) *y = 0; if (on) *on = 0; if (buttons) *buttons = 0;
}
void koru_wire(const uint8_t *s, size_t n) {
    FILE *fp = fopen("/tmp/kn_wire.bin", "ab");
    if (fp) { fwrite(s, 1, n, fp); fclose(fp); }
}
uint8_t koru_glyph8(uint8_t ch, uint8_t row) { (void)ch; (void)row; return 0; }
uint64_t ukplat_monotonic_clock(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

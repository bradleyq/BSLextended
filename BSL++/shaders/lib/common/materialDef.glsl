#define none_mat 0.0
#define water_mat 0.1
#define trans_mat 0.15
#define block_mat 0.20
#define foliage_mat 0.25
#define emissive_mat 0.30
#define lava_mat 0.35
#define metal_mat 0.40
#define fire_mat 0.45
#define undefined_mat 1.0

bool matches(float l, float r) {
    return l > r - 0.01 && l < r + 0.01;
}
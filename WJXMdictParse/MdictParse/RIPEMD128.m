#import "RIPEMD128.h"


// RIPEMD128 实现
// 基于 JavaScript 版本的 RIPEMD128 算法移植

// 左旋转函数
static inline uint32_t rotl(uint32_t x, uint32_t n) {
    return (x << n) | (x >> (32 - n));
}

// 轮函数
static inline uint32_t F1(uint32_t x, uint32_t y, uint32_t z) {
    return x ^ y ^ z;
}

static inline uint32_t F2(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) | (~x & z);
}

static inline uint32_t F3(uint32_t x, uint32_t y, uint32_t z) {
    return (x | ~y) ^ z;
}

static inline uint32_t F4(uint32_t x, uint32_t y, uint32_t z) {
    return (x & z) | (y & ~z);
}

// 轮移位常量
static const uint32_t S[8][16] = {
    {11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8},    // 轮 1
    {7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12},    // 轮 2
    {11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5},    // 轮 3
    {11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12},    // 轮 4
    {8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6},    // 并行轮 1
    {9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11},    // 并行轮 2
    {9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5},    // 并行轮 3
    {15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8}     // 并行轮 4
};

// 轮索引常量
static const uint32_t X[8][16] = {
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},      // 轮 1
    {7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8},      // 轮 2
    {3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12},      // 轮 3
    {1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2},      // 轮 4
    {5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12},      // 并行轮 1
    {6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2},      // 并行轮 2
    {15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13},      // 并行轮 3
    {8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14}       // 并行轮 4
};

// 轮常量
static const uint32_t K[8] = {
    0x00000000,     // FF
    0x5a827999,     // GG
    0x6ed9eba1,     // HH
    0x8f1bbcdc,     // II
    0x50a28be6,     // III
    0x5c4dd124,     // HHH
    0x6d703ef3,     // GGG
    0x00000000      // FFF
};

@implementation RIPEMD128

// 计算RIPEMD128哈希值
+ (NSData *)ripemd128HashForData:(NSData *)data {
    if (data == nil) {
        return nil;
    }
    
    // 初始哈希值
    uint32_t hash[4] = {
        0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    };
    
    // 获取数据长度和指针
    NSUInteger bytes = data.length;
   // const uint8_t *dataBytes = data.bytes;
    
    // 创建填充数据
    NSUInteger paddingLength = (bytes % 64 < 56 ? 56 : 120) - (bytes % 64);
    NSMutableData *paddingData = [NSMutableData dataWithLength:paddingLength];
    uint8_t *padding = paddingData.mutableBytes;
    padding[0] = 0x80;  // 第一个填充字节为0x80，其余为0
    
    // 创建长度数据（64位小端序整数，表示原始数据的位长度）
    NSMutableData *lengthData = [NSMutableData dataWithLength:8];
    uint32_t *lengthBytes = lengthData.mutableBytes;
    uint64_t bitLength = bytes * 8;
    lengthBytes[0] = (uint32_t)(bitLength & 0xFFFFFFFF);
    lengthBytes[1] = (uint32_t)(bitLength >> 32);
    
    // 合并所有数据
    NSMutableData *processData = [NSMutableData dataWithData:data];
    [processData appendData:paddingData];
    [processData appendData:lengthData];
    
    // 处理数据块
    const uint32_t *x = processData.bytes;
    NSUInteger blockCount = processData.length / 64;
    
    for (NSUInteger i = 0; i < blockCount; i++) {
        uint32_t aa = hash[0];
        uint32_t bb = hash[1];
        uint32_t cc = hash[2];
        uint32_t dd = hash[3];
        uint32_t aaa = hash[0];
        uint32_t bbb = hash[1];
        uint32_t ccc = hash[2];
        uint32_t ddd = hash[3];
        
        uint32_t tmp;
        const uint32_t *block = x + (i * 16);
        
        // 64步主循环
        for (int t = 0; t < 64; t++) {
            int r = t / 16;
            
            // 计算左侧
            if (r == 0) {
                aa = rotl(aa + F1(bb, cc, dd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else if (r == 1) {
                aa = rotl(aa + F2(bb, cc, dd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else if (r == 2) {
                aa = rotl(aa + F3(bb, cc, dd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else {
                aa = rotl(aa + F4(bb, cc, dd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            }
            
            // 循环移位
            tmp = dd;
            dd = cc;
            cc = bb;
            bb = aa;
            aa = tmp;
        }
        
        // 64步并行循环
        for (int t = 0; t < 64; t++) {
            int r = t / 16 + 4;
            int rr = 3 - (t / 16);
            
            // 计算右侧
            if (rr == 0) {
                aaa = rotl(aaa + F1(bbb, ccc, ddd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else if (rr == 1) {
                aaa = rotl(aaa + F2(bbb, ccc, ddd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else if (rr == 2) {
                aaa = rotl(aaa + F3(bbb, ccc, ddd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            } else {
                aaa = rotl(aaa + F4(bbb, ccc, ddd) + block[X[r][t % 16]] + K[r], S[r][t % 16]);
            }
            
            // 循环移位
            tmp = ddd;
            ddd = ccc;
            ccc = bbb;
            bbb = aaa;
            aaa = tmp;
        }
        
        // 合并结果
        ddd = hash[1] + cc + ddd;
        hash[1] = hash[2] + dd + aaa;
        hash[2] = hash[3] + aa + bbb;
        hash[3] = hash[0] + bb + ccc;
        hash[0] = ddd;
    }
    
    // 转换为小端序输出
    NSMutableData *result = [NSMutableData dataWithLength:16];
    uint32_t *resultBytes = result.mutableBytes;
    for (int i = 0; i < 4; i++) {
        resultBytes[i] = hash[i];
    }
    
    return result;
}





@end

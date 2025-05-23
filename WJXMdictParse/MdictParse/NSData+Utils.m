
#import <Foundation/Foundation.h>
#import "RIPEMD128.h"
#import "minilzo.h"
#import <zlib.h>
@implementation NSData (Utils)

- (NSUInteger)wjx_uint8BEtoNumber {
    const uint8_t *bytes = [self bytes];
    return bytes[0] & 0xff;;
}

- (NSUInteger)wjx_uint16BEtoNumber {
    const uint8_t *bytes = [self bytes];
    NSUInteger n = 0;
    
    for (NSInteger i = 0; i < 1; i++) {
        n |= bytes[i];   // 将字节与 n 按位或
        n <<= 8;          // 左移 8 位，为下一个字节腾出空间
    }
    
    n |= bytes[1];       // 最后将最后一个字节与 n 按位或
    return n;
}

- (NSUInteger)wjx_uint32BEtoNumber {
    const uint8_t *bytes = [self bytes];
    NSUInteger n = 0;
    
    for (NSInteger i = 0; i < 3; i++) {
        n |= bytes[i];   // 将字节与 n 按位或
        n <<= 8;          // 左移 8 位，为下一个字节腾出空间
    }
    
    n |= bytes[3];       // 最后将最后一个字节与 n 按位或
    return n;
}

- (NSUInteger)wjx_uint64BEtoNumber {
    const uint8_t *bytes = [self bytes];
    NSAssert(bytes[0] == 0 && bytes[1] < 0x20, @"Error: uint64 larger than 2^53, JS may lost accuracy");
    
    uint32_t high = 0;
    for (NSInteger i = 0; i < 3; i++) {
        high |= bytes[i] & 0xff;
        high <<= 8;
    }
    high |= bytes[3] & 0xff;
    high = (high & 0x001fffff) * (uint32_t)0x100000000;
    high += bytes[4] * 0x1000000;
    high += bytes[5] * 0x10000;
    high += bytes[6] * 0x100;
    high += bytes[7] & 0xff;
    return high;
}



- (NSUInteger)wjx_b2n {
    switch (self.length) {
        case 1: return [self wjx_uint8BEtoNumber];
        case 2: return [self wjx_uint16BEtoNumber];
        case 4: return [self wjx_uint32BEtoNumber];
        case 8: return [self wjx_uint64BEtoNumber];
        default: return 0;
    }
}

- (NSString *)wjx_hexString {
    NSMutableString *packType = [NSMutableString string];

    for (NSUInteger i = 0; i < self.length; i++) {
        uint8_t byte;
        [self getBytes:&byte range:NSMakeRange(i, 1)];
        [packType appendFormat:@"%02x", byte];  // 用 2 位十六进制表示
    }

    NSLog(@"packType: %@", packType);
    return [packType copy];
}


/**
 * MDX解密函数
 * 将压缩块进行解密处理
 * @return 解密后的数据
 */
- (NSData *)wjx_mdxDecrypt {
    // 确保数据长度足够
    if (self.length <= 8) {
        return self;
    }
    
    // 创建keyinBuffer
    NSMutableData *keyinBuffer = [NSMutableData dataWithLength:8];
    uint8_t *keyinBytes = (uint8_t *)[keyinBuffer mutableBytes];
    
    // 复制comp_block[4:8]到keyinBuffer[0:4]
    const uint8_t *sourceBytes = [self bytes];
    memcpy(keyinBytes, sourceBytes + 4, 4);
    
    // 异或操作
    keyinBytes[4] ^= 0x95;
    keyinBytes[5] ^= 0x36;
    keyinBytes[6] ^= 0x00;
    keyinBytes[7] ^= 0x00;
    
    // 计算RIPEMD128哈希
    NSData *key = [RIPEMD128 ripemd128HashForData:[NSData dataWithBytes:keyinBytes length:8]];
    
    // 创建结果数据
    NSMutableData *resultData = [NSMutableData dataWithCapacity:self.length];
    
    // 复制前8个字节到结果数据
    [resultData appendBytes:sourceBytes length:8];
    
    // 获取剩余部分的数据
    NSData *remainingData = [self subdataWithRange:NSMakeRange(8, self.length - 8)];
    
    // 使用快速解密算法处理剩余部分
    NSData *decryptedData = [remainingData wjx_fastDecryptWithKey:key];
    
    // 将解密后的数据添加到结果中
    [resultData appendData:decryptedData];
    
    return resultData;
}

/**
 * 快速解密算法
 * @param key 解密密钥
 * @return 解密后的数据
 */
- (NSData *)wjx_fastDecryptWithKey:(NSData *)key {
    // 确保key不为空
    if (!key || key.length == 0) {
        return self;
    }
    
    // 创建可变数据用于存储结果
    NSMutableData *resultData = [NSMutableData dataWithLength:self.length];
    
    // 获取源数据和结果数据的字节指针
    const uint8_t *sourceBytes = self.bytes;
    uint8_t *resultBytes = resultData.mutableBytes;
    
    // 获取密钥字节
    const uint8_t *keyBytes = key.bytes;
    NSUInteger keyLength = key.length;
    
    // 执行解密操作
    uint8_t previous = 0x36;
    
    for (NSUInteger i = 0; i < self.length; ++i) {
        // 执行右移4位或左移4位的操作，并保持在8位范围内
        uint8_t t = ((sourceBytes[i] >> 4) | (sourceBytes[i] << 4)) & 0xff;
        
        // 异或操作：t ^ previous ^ (i & 0xff) ^ key[i % key.length]
        t = t ^ previous ^ (i & 0xff) ^ keyBytes[i % keyLength];
        
        // 保存当前字节作为下一轮的previous
        previous = sourceBytes[i];
        
        // 存储解密结果
        resultBytes[i] = t;
    }
    
    return resultData;
}


- (NSData *)wjx_unpackKeyBlock:(NSUInteger)unpackSize {
    
    // 检查数据长度是否足够
    if (self.length < 8) {
        NSLog(@"数据长度不足，无法解包关键块");
        return nil;
    }
    
    // 读取压缩类型（前4个字节）
    NSData *compTypeData = [self subdataWithRange:NSMakeRange(0, 4)];
    const uint8_t *compTypeBytes = compTypeData.bytes;
    
    // 创建结果数据
    NSData *keyBlock = nil;
    
    // 根据压缩类型进行不同处理
    if (compTypeBytes[0] == 0 && compTypeBytes[1] == 0 && compTypeBytes[2] == 0 && compTypeBytes[3] == 0) {
        // 未压缩类型 (00000000)
        keyBlock = [self subdataWithRange:NSMakeRange(8, self.length - 8)];
    } else if (compTypeBytes[0] == 1 && compTypeBytes[1] == 0 && compTypeBytes[2] == 0 && compTypeBytes[3] == 0) {
        // LZO压缩类型 (01000000)
        NSData *compressedData = [self subdataWithRange:NSMakeRange(8, self.length - 8)];
        keyBlock = [compressedData wjx_lzo1xDecompress:unpackSize];
    } else if (compTypeBytes[0] == 2 && compTypeBytes[1] == 0 && compTypeBytes[2] == 0 && compTypeBytes[3] == 0) {
        // zlib压缩类型 (02000000)
        NSData *compressedData = [self subdataWithRange:NSMakeRange(8, self.length - 8)];
        keyBlock = [compressedData wjx_zlibDecode:unpackSize];
    } else {
        NSLog(@"无法确定压缩类型: %02x%02x%02x%02x", 
              compTypeBytes[0], compTypeBytes[1], compTypeBytes[2], compTypeBytes[3]);
        return nil;
    }
    
    // TODO: 验证adler32校验和
    // NSData *checksumData = [self subdataWithRange:NSMakeRange(4, 4)];
    
    return keyBlock;
}


- (NSData *)wjx_lzo1xDecompress:(NSUInteger)unpackSize {
    // 初始化 LZO
    if (lzo_init() != LZO_E_OK) {
        NSLog(@"LZO initialization failed");
        return nil;
    }
    
    // 准备输入数据
    const unsigned char *in = (const unsigned char *)[self bytes];
    lzo_uint in_len = (lzo_uint)[self length];
    
    // 准备输出缓冲区
    unsigned char *output = (unsigned char *)malloc(unpackSize);
    if (!output) {
        NSLog(@"Failed to allocate output buffer");
        return nil;
    }
    
    // 执行解压
    lzo_uint new_len = unpackSize;
    int r = lzo1x_decompress(in, in_len, output, &new_len, NULL);
    if (r != LZO_E_OK || new_len != unpackSize) {
        NSLog(@"Decompression failed: %d", r);
        free(output);
        return nil;
    }
    
    // 创建解压后的数据对象
    NSData *decompressedData = [NSData dataWithBytes:output length:new_len];
    free(output);
    
    return decompressedData;
}

- (NSData *)wjx_zlibDecode:(NSUInteger)unpackSize {
    
    // 使用 zlib 解压缩
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = (uInt)self.length;
    strm.next_in = (Bytef *)self.bytes;
    
    // 初始化解压缩
    int ret = inflateInit(&strm);
    if (ret != Z_OK) {
        NSLog(@"zlib 初始化失败: %d", ret);
        return nil;
    }
    
    // 创建输出缓冲区
    NSMutableData *unpackedData = [NSMutableData dataWithLength:unpackSize];
    strm.avail_out = (uInt)unpackSize;
    strm.next_out = unpackedData.mutableBytes;
    
    // 执行解压缩
    ret = inflate(&strm, Z_FINISH);
    inflateEnd(&strm);
    
    if (ret != Z_STREAM_END) {
        NSLog(@"zlib 解压缩失败: %d", ret);
        return nil;
    }
    return unpackedData;
    
 
}

@end

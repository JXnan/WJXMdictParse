
#import "WJXMdict.h"
#import "WJXMdictOptions.h"

#import "NSData+Utils.h"

@implementation WJXMdict

- (instancetype)initWithFilename:(NSString *)fname options:(WJXMdictOptions *)options {
    // 默认选项
    if (!options) {
        options = [[WJXMdictOptions alloc] init];
    }
    
    // 设置选项默认值
    options.passcode = options.passcode ?: @"";
    options.debug = options.debug ?: NO;
    options.resort = options.resort ?: YES;
    options.isStripKey = options.isStripKey ?: YES;
    options.isCaseSensitive = options.isCaseSensitive ?: YES;
    options.encryptType = options.encryptType ?: -1;
    
    // 调用父类初始化方法
    NSString *passcode = options.passcode.length > 0 ? options.passcode : nil;
    self = [super initWithFilename:fname passcode:passcode options:options];
    
    return self;
}

/**
 * 通过关键词查找关键词块
 * @param word 目标词语
 * @param isAssociate 是否为关联查询
 * @return 关键词项
 */
- (WJXKeyWordItem *)lookupKeyBlockByWord:(NSString *)word isAssociate:(BOOL)isAssociate {
    NSArray *list = self.keywordList;
    NSInteger left = 0;
    NSInteger right = list.count - 1;
    NSInteger mid = 0;
    
    // 二分查找
    while (left <= right) {
        mid = left + ((right - left) >> 1);
        
        WJXKeyWordItem *item = list[mid];
        NSComparisonResult compRes = [self comp:word withWord2:item.keyText];
        
        if (compRes == NSOrderedDescending) {
            left = mid + 1;
        } else if (compRes == NSOrderedSame) {
            break;
        } else {
            right = mid - 1;
        }
    }
    
    // 如果没有找到完全匹配且不是关联查询，则返回nil
    if ([self comp:word withWord2:[list[mid] keyText]] != NSOrderedSame && !isAssociate) {
        return nil;
    }
    
    return list[mid];
}

/**
 * 通过关键词项查找记录含义
 * 关键词项的recordStartOffset指示记录块信息的位置
 * 使用记录块信息，我们可以获取recordBuffer，然后需要解密和解压
 * 使用解压后的recordBuffer，我们可以获取包含含义的整个块
 * 然后使用：
 *  const start = item.recordStartOffset - recordBlockInfo.unpackAccumulatorOffset;
 *  const end = item.recordEndOffset - recordBlockInfo.unpackAccumulatorOffset;
 *  最终含义的缓冲区是 unpackRecordBlockBuff[start, end]
 * @param item 关键词项
 * @return 记录含义的数据
 */
- (NSData *)lookupRecordByKeyBlock:(WJXKeyWordItem *)item {
    // 查找记录块索引
    NSInteger recordBlockIndex = [self reduceRecordBlockInfo:item.recordStartOffset];
    
    // 获取记录块信息
    WJXRecordInfo *recordBlockInfo = self.recordInfoList[recordBlockIndex];
    
    // 读取记录缓冲区
    NSData *recordBuffer = [self.scanner readBufferFromOffset:self.recordBlockStartOffset + recordBlockInfo.packAccumulateOffset length:recordBlockInfo.packSize];
    
    // 解压记录块
    NSData *unpackRecordBlockBuff = [self decompressBuff:recordBuffer unpackSize:recordBlockInfo.unpackSize];
    
    // 计算记录含义的起始和结束位置
    NSUInteger start = item.recordStartOffset - recordBlockInfo.unpackAccumulatorOffset;
    NSUInteger end = item.recordEndOffset - recordBlockInfo.unpackAccumulatorOffset;
    
    // 提取记录含义
    return [unpackRecordBlockBuff subdataWithRange:NSMakeRange(start, end - start)];
}

/**
 * 查找记录块索引
 * @param recordStartOffset 记录起始偏移量
 * @return 记录块索引
 */
- (NSInteger)reduceRecordBlockInfo:(NSUInteger)recordStartOffset {
    NSInteger left = 0;
    NSInteger right = self.recordInfoList.count - 1;
    
    while (left <= right) {
        NSInteger mid = left + ((right - left) >> 1);
        WJXRecordInfo *recordInfo = self.recordInfoList[mid];
        
        if (recordStartOffset >= recordInfo.unpackAccumulatorOffset && 
            recordStartOffset < recordInfo.unpackAccumulatorOffset + recordInfo.unpackSize) {
            return mid;
        } else if (recordStartOffset < recordInfo.unpackAccumulatorOffset) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    
    return -1; // 未找到匹配的记录块
}



/**
 * 解压缩记录缓冲区
 * @param recordBuffer 记录缓冲区数据
 * @param unpackSize 解压后的大小
 * @return 解压后的数据
 */
- (NSData *)decompressBuff:(NSData *)recordBuffer unpackSize:(NSUInteger)unpackSize {
    // 获取压缩类型（前4个字节）
    NSData *rbCompType = [recordBuffer subdataWithRange:NSMakeRange(0, 4)];
    NSData *unpackRecordBlockBuff = nil;
    
    // 将压缩类型转换为十六进制字符串进行比较
    NSString *compTypeHex = [rbCompType wjx_hexString];
    
    // 如果压缩类型为0，表示未压缩
    if ([compTypeHex isEqualToString:@"00000000"]) {
        // 跳过前8个字节（压缩类型4字节 + adler32校验和4字节）
        unpackRecordBlockBuff = [recordBuffer subdataWithRange:NSMakeRange(8, recordBuffer.length - 8)];
    } else {
        // 解密处理
        NSData *blockBufDecrypted = nil;
        
        // 如果加密类型为1，需要解密记录块
        if (self.meta.encrypt == 1) {
            blockBufDecrypted = [recordBuffer wjx_mdxDecrypt];
        } else {
            // 跳过前8个字节（压缩类型4字节 + adler32校验和4字节）
            blockBufDecrypted = [recordBuffer subdataWithRange:NSMakeRange(8, recordBuffer.length - 8)];
        }
        
        // 根据压缩类型进行解压
        if ([compTypeHex isEqualToString:@"01000000"]) {
            // LZO1X解压
            unpackRecordBlockBuff = [blockBufDecrypted wjx_lzo1xDecompress:unpackSize];
        } else if ([compTypeHex isEqualToString:@"02000000"]) {
            // zlib解压
            unpackRecordBlockBuff = [blockBufDecrypted wjx_zlibDecode:unpackSize];
        }
    }
    
    return unpackRecordBlockBuff;
}




@end

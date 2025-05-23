//
//  WJXMdictBase.h
//

#import <UIKit/UIKit.h>
#import "WJXMdictBase.h"
#import "NSData+Utils.h"
#import "NSString+Mdict.h"
#import <zlib.h>
#import "WJXKeyWordItem.h"



@class WJXFileScanner;



@interface WJXMdictBase()


@end

@implementation WJXMdictBase {
    // header start offset
    NSUInteger _headerStartOffset;
    // header end offset
    NSUInteger _headerEndOffset;
    
    // keyHeader start offset
    NSUInteger _keyHeaderStartOffset;
    // keyHeader end offset
    NSUInteger _keyHeaderEndOffset;
    
    // keyBlockInfo start offset
    NSUInteger _keyBlockInfoStartOffset;
    // keyBlockInfo end offset
    NSUInteger _keyBlockInfoEndOffset;
    
    // keyBlock start offset
    NSUInteger _keyBlockStartOffset;
    // keyBlock end offset
    NSUInteger _keyBlockEndOffset;
    
    // recordHeader start offset
    NSUInteger _recordHeaderStartOffset;
    // recordHeader end offset
    NSUInteger _recordHeaderEndOffset;
    
    // recordInfo start offset
    NSUInteger _recordInfoStartOffset;
    // recordInfo end offset
    NSUInteger _recordInfoEndOffset;
    
    // recordBlock end offset
    NSUInteger _recordBlockEndOffset;
  
}

/**
 * 初始化字典
 * @param filename 文件路径
 * @param passcode 密码（可选）
 * @param options 选项（可选）
 */
- (instancetype)initWithFilename:(NSString *)filename 
                        passcode:(NSString *)passcode 
                         options:(WJXMdictOptions *)options {
    if (self = [super init]) {
        // 初始化元数据
        _meta = [[WJXMdictMeta alloc] init];
        _meta.fname = filename;
        _meta.passcode = passcode;
        _meta.ext = [filename pathExtension];
        if (_meta.ext.length == 0) {
            _meta.ext = @"mdx";
        }
        _meta.version = 2.0;
        _meta.numWidth = 4;
        _meta.numFmt = kNumFmtUint32;
        _meta.encoding = NSUTF8StringEncoding;
        _meta.encrypt = 0;
        
        // 初始化文件扫描器
        _scanner = [[WJXFileScanner alloc] initWithFilename:filename];
        
        // 设置选项
        if (options) {
            _options = options;
        } else {
            _options = [WJXMdictOptions defaultOptions];
            _options.passcode = passcode;
        }
        
        // 初始化各部分数据结构
        // 头部信息相关
		_headerStartOffset = 0;
		_headerEndOffset = 0;        
        _header = [NSMutableDictionary dictionary];
        
        // 关键词头部信息
		_keyHeaderStartOffset = 0;
		_keyHeaderEndOffset = 0;
        _keyHeader = [[WJXKeyHeader alloc] init];
        
        // 关键词块信息列表
		_keyBlockInfoStartOffset = 0;
		_keyBlockInfoEndOffset = 0;
        _keyInfoList = [NSArray array];
        
        // 关键词列表
		_keyBlockStartOffset = 0;
		_keyBlockEndOffset = 0;
        _keywordList = [NSMutableArray array];
        
        // 记录头部信息
		_recordHeaderStartOffset = 0;
		_recordHeaderEndOffset = 0;
        _recordHeader = [[WJXRecordHeader alloc] init];
        
        // 记录信息列表
		_recordInfoStartOffset = 0;
		_recordInfoEndOffset = 0;
        _recordInfoList = [NSArray array];
        
        // 记录块数据列表
		_recordBlockStartOffset = 0;
		_recordBlockEndOffset = 0;
        _recordBlockDataList = [NSMutableArray array];
        
        // 读取字典数据
        [self readDict];
    }
    return self;
}

/**
 * 处理关键词，移除特殊字符
 * @param key 关键词
 * @return 处理后的关键词
 */
- (NSString *)strip:(NSString *)key {
    // 如果需要移除特殊字符
    if ([self isStripKey]) {
        // 根据字典扩展名选择正则表达式进行处理
        NSRegularExpression *regex = [self getStripKeyRegexForExt:self.meta.ext];
        if (regex) {
            key = [regex stringByReplacingMatchesInString:key 
                                                 options:0 
                                                   range:NSMakeRange(0, key.length) 
                                            withTemplate:@"$1"];
        }
    }
    
    // 如果不区分大小写
    if (![self isKeyCaseSensitive]) {
        key = [key lowercaseString];
    }
    
    // 对MDD文件特殊处理
    if ([self.meta.ext isEqualToString:@"mdd"]) {
        NSRegularExpression *regex = [self getStripKeyRegexForExt:self.meta.ext];
        if (regex) {
            key = [regex stringByReplacingMatchesInString:key 
                                                 options:0 
                                                   range:NSMakeRange(0, key.length) 
                                            withTemplate:@"$1"];
        }
        key = [key stringByReplacingOccurrencesOfString:@"_" withString:@"!"];
    }
    
    // 返回处理后的小写并去除首尾空格的关键词
    return [[key lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}



/**
 * 比较两个词
 * @param word1 第一个词
 * @param word2 第二个词
 * @return 比较结果
 */
- (NSComparisonResult)comp:(NSString *)word1 withWord2:(NSString *)word2 {
    return [word1 localizedCompare:word2];
}

/**
 * 读取字典数据
 */
- (void)readDict {
    [self readHeader];
    [self readKeyHeader];
    [self readKeyInfos];
    [self readKeyBlocks];
    [self readRecordHeader];
    [self readRecordInfos];
    
    // 对关键词列表进行排序
    [_keywordList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *keyText1 = [obj1 keyText];
        NSString *keyText2 = [obj2 keyText];
        return [keyText1 localizedCompare:keyText2];
    }];
}

- (void)readHeader {
	NSData * headerByteSizeBuff = [_scanner readBufferFromOffset:0 length:4];
	NSUInteger headerByteSize = [headerByteSizeBuff wjx_b2n];

	NSData * headerBuff = [_scanner readBufferFromOffset:4 length:headerByteSize];
    _headerEndOffset = headerByteSize + 4 + 4;
    _keyHeaderStartOffset = headerByteSize + 4 + 4;

    NSString * headerText = [[NSString alloc] initWithData:headerBuff encoding:NSUTF16LittleEndianStringEncoding];
    
    
    _header = [[NSString wjx_parseHeader:headerText] mutableCopy];
    _header[@"KeyCaseSensitive"] = _header[@"KeyCaseSensitive"] ?: @"No";
    _header[@"StripKey"] = _header[@"StripKey"] ?: @"Yes";
    
    NSString *encrypted = _header[@"Encrypted"] ?: @"No";
    if ([encrypted isEqualToString:@""] || [encrypted isEqualToString:@"No"] ) {
        _meta.encrypt = 0;
    }else if([encrypted isEqualToString:@"Yes"]) {
        _meta.encrypt = 1;
    }else {
        _meta.encrypt = [encrypted integerValue];
    }
    
    if(_options.encryptType && _options.encryptType != -1) {
        _meta.encrypt = _options.encryptType;
    }
	
    // 设置版本信息
    _meta.version = [_header[@"GeneratedByEngineVersion"] floatValue];
    
    // 根据版本设置数字宽度和格式
    if (_meta.version >= 2.0) {
        _meta.numWidth = 8;
        _meta.numFmt = kNumFmtUint64;
    } else {
        _meta.numWidth = 4;
        _meta.numFmt = kNumFmtUint32;
    }
    
    // 设置编码
    if (!_header[@"Encoding"] || [_header[@"Encoding"] isEqualToString:@""]) {
        _meta.encoding = NSUTF8StringEncoding;
    } else if ([_header[@"Encoding"] isEqualToString:@"GBK"] || [_header[@"Encoding"] isEqualToString:@"GB2312"]) {
        _meta.encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    } else if ([[_header[@"Encoding"] lowercaseString] isEqualToString:@"big5"]) {
        _meta.encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
    } else {
        NSString *encodingLower = [_header[@"Encoding"] lowercaseString];
        if ([encodingLower isEqualToString:@"utf16"] || [encodingLower isEqualToString:@"utf-16"]) {
            _meta.encoding = NSUTF16LittleEndianStringEncoding;
        } else {
            _meta.encoding = NSUTF8StringEncoding;
        }
    }
    
    // 如果扩展名是mdd，设置为UTF16编码
    if ([_meta.ext isEqualToString:@"mdd"]) {
        _meta.encoding = NSUTF16LittleEndianStringEncoding;
    }

}

- (void)readKeyHeader {
    // 设置关键头部起始偏移量
    _keyHeaderStartOffset = _headerEndOffset;
    
    // 根据版本确定头部元数据大小
    // 版本 >= 2.0，关键头部字节数为 5 * 8，否则为 4 * 4
    NSInteger headerMetaSize = _meta.version >= 2.0 ? 8 * 5 : 4 * 4;
    
    // 读取关键头部缓冲区
    NSData *keyHeaderBuff = [self.scanner readBufferFromOffset:_keyHeaderStartOffset length:headerMetaSize];

    // 检查是否需要解密
    if (_meta.encrypt & 1) {
        if (!_meta.passcode || [_meta.passcode isEqualToString:@""]) {
            // TODO: 加密文件暂不支持
            NSLog(@"需要用户身份验证才能读取加密文件");
            return;
        }
        
        // 根据注册方式处理
        if ([_header[@"RegisterBy"] isEqualToString:@"Email"]) {
            // 通过邮箱解密注册码
            // encrypted_key = _decrypt_regcode_by_email(regcode, userid);
            NSLog(@"暂不支持加密文件");
            return;
        } else {
            NSLog(@"暂不支持加密文件");
            return;
        }
    }

    // 解析关键头部数据
    NSInteger offset = 0;
    
    // [0:8] - 关键块数量
    NSData *keywordBlockNumBuff = [keyHeaderBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    _keyHeader.keywordBlocksNum = [keywordBlockNumBuff wjx_b2n];
    offset += _meta.numWidth;
    
    // [8:16] - 词条数量
    NSData *keywordNumBuff = [keyHeaderBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    _keyHeader.keywordNum = [keywordNumBuff wjx_b2n];
    offset += _meta.numWidth;

    // 仅适用于版本 >= 2.0
    if (_meta.version >= 2.0) {
        // [16:24] - 关键信息解压缩大小
        NSData *keyInfoUnpackSizeBuff = [keyHeaderBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
        _keyHeader.keyInfoUnpackSize = [keyInfoUnpackSizeBuff wjx_b2n];
        offset += _meta.numWidth;
    }
    
    // [24:32] - 关键信息压缩大小
    NSData *keyInfoPackedSizeBuff = [keyHeaderBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    _keyHeader.keyInfoPackedSize = [keyInfoPackedSizeBuff wjx_b2n];
    offset += _meta.numWidth;

    // [32:40] - 关键词块压缩大小
    NSData *keywordBlockPackedSizeBuff = [keyHeaderBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    _keyHeader.keywordBlockPackedSize = [keywordBlockPackedSizeBuff wjx_b2n];
    offset += _meta.numWidth;
    
    // 设置关键头部结束偏移量
    _keyHeaderEndOffset = _keyHeaderStartOffset + headerMetaSize + (_meta.version >= 2.0 ? 4 : 0); // 4字节adler32校验和长度，仅适用于版本 >= 2.0

}

- (void)readKeyInfos {
    _keyBlockInfoStartOffset = _keyHeaderEndOffset;
    NSData *keyBlockInfoBuff = [_scanner readBufferFromOffset:_keyBlockInfoStartOffset length:_keyHeader.keyInfoPackedSize];
    NSArray<WJXKeyInfoItem *> * keyBlockInfoList = [self decodeKeyInfo:keyBlockInfoBuff];
    
    // 设置关键块信息结束偏移量
    _keyBlockInfoEndOffset = _keyBlockInfoStartOffset + _keyHeader.keyInfoPackedSize;
    
    // 确保关键块数量与解析出的关键块信息列表长度一致
    NSAssert(_keyHeader.keywordBlocksNum == keyBlockInfoList.count, @"关键块数量应该等于关键块信息列表长度");
    
    // 保存关键块信息列表
    _keyInfoList = keyBlockInfoList;
    
    // 注意：必须在这里设置，否则如果我们没有调用_decodeKeyBlockInfo方法，
    // 变量`_recordBlockStartOffset`将不会被设置。
    _recordBlockStartOffset = _keyBlockInfoEndOffset + _keyHeader.keywordBlockPackedSize;
    
}

- (NSArray<WJXKeyInfoItem *> *)decodeKeyInfo:(NSData *)keyInfoBuff {
    NSUInteger keyBlockNum = _keyHeader.keywordBlocksNum;
    if (_meta.version == 2.0) {
        // 获取压缩类型
        NSData *packTypeBuff = [keyInfoBuff subdataWithRange:NSMakeRange(0, 4)];
        NSMutableString *packType = [NSMutableString string];
        
        // 将每个字节转换成字符并拼接到 packType 字符串中
        const uint8_t *bytes = [packTypeBuff bytes];
        for (NSUInteger i = 0; i < packTypeBuff.length; i++) {
            [packType appendFormat:@"%d", bytes[i]];
        }

        
        // 如果是加密的数据，先解密
        if (_meta.encrypt == 2) {
            keyInfoBuff = [keyInfoBuff wjx_mdxDecrypt];
        }
        
        // 检查压缩数据大小是否与预期一致
        NSAssert(_keyHeader.keyInfoPackedSize == keyInfoBuff.length, @"key_block_info keyInfoPackedSize %lu 应该等于 key-info buffer length %lu", (unsigned long)_keyHeader.keyInfoPackedSize, (unsigned long)keyInfoBuff.length);
        
        // 对于版本 2.0 及以上，使用 zlib 解压缩
        if (_meta.version >= 2.0 && [packType isEqualToString:@"2000"]) {
            // 从第8个字节开始是压缩数据
            NSData *compressedData = [keyInfoBuff subdataWithRange:NSMakeRange(8, keyInfoBuff.length - 8)];
            
            NSData *unpackedData = [compressedData wjx_zlibDecode:_keyHeader.keyInfoUnpackSize];
            
            // 验证解压后的大小是否符合预期
            NSAssert(_keyHeader.keyInfoUnpackSize == unpackedData.length, @"key_block_info keyInfoUnpackSize %lu 应该等于 keyInfoBuffUnpacked buffer length %lu", (unsigned long)_keyHeader.keyInfoUnpackSize, (unsigned long)unpackedData.length);
            
            // 用解压后的数据替换原始数据
            keyInfoBuff = unpackedData;
        }
    }

	NSMutableArray<WJXKeyInfoItem *> * keyBlockInfoList = [NSMutableArray array];

	// 初始化累加器变量
	NSInteger entriesCount = 0;
	NSInteger kbCount = 0;
	NSInteger indexOffset = 0;
	NSInteger kbPackSizeAccu = 0;
	NSInteger kbUnpackSizeAccu = 0;
	
	while (kbCount < keyBlockNum) { 
		// 读取关键块信息
		NSInteger blockWordCount = 0;
		NSInteger packSize = 0;
		NSInteger unpackSize = 0;
		NSInteger firstWordSize = 0;
		NSInteger lastWordSize = 0;
		NSString *firstKey = nil;
		NSString *lastKey = nil;
		
		// 读取块中的词条数量
		NSData *blockWordCountBuff = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, _meta.numWidth)];
		blockWordCount = [blockWordCountBuff wjx_b2n];
		indexOffset += _meta.numWidth;
		
		// 读取第一个词的大小
		NSData *firstWordSizeBuff = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, _meta.numWidth / 4)];
		firstWordSize = [firstWordSizeBuff wjx_b2n];
		indexOffset += _meta.numWidth / 4;
		
		// 根据版本和编码调整第一个词的大小
		if (_meta.version >= 2.0) {
			if (_meta.encoding == NSUTF16LittleEndianStringEncoding) {
				firstWordSize = (firstWordSize + 1) * 2;
			} else {
				firstWordSize += 1;
			}
		} else {
			if (_meta.encoding == NSUTF16LittleEndianStringEncoding) {
				firstWordSize = firstWordSize * 2;
			}
		}
		
		// 读取第一个词
		NSData *firstWordBuffer = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, firstWordSize)];
		indexOffset += firstWordSize;
		
		// 读取最后一个词的大小
		NSData *lastWordSizeBuff = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, _meta.numWidth / 4)];
		lastWordSize = [lastWordSizeBuff wjx_b2n];
		indexOffset += _meta.numWidth / 4;
		
		// 根据版本和编码调整最后一个词的大小
		if (_meta.version >= 2.0) {
			if (_meta.encoding == NSUTF16LittleEndianStringEncoding) {
				lastWordSize = (lastWordSize + 1) * 2;
			} else {
				lastWordSize += 1;
			}
		} else {
			if (_meta.encoding == NSUTF16LittleEndianStringEncoding) {
				lastWordSize = lastWordSize * 2;
			}
		}
		
		// 读取最后一个词
		NSData *lastWordBuffer = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, lastWordSize)];
		indexOffset += lastWordSize;
		
		// 读取压缩大小
		NSData *packSizeBuff = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, _meta.numWidth)];
		packSize = [packSizeBuff wjx_b2n];
		indexOffset += _meta.numWidth;
		
		// 读取解压大小
		NSData *unpackSizeBuff = [keyInfoBuff subdataWithRange:NSMakeRange(indexOffset, _meta.numWidth)];
		unpackSize = [unpackSizeBuff wjx_b2n];
		indexOffset += _meta.numWidth;
		
        // 解码第一个和最后一个关键词
        firstKey = [[NSString alloc] initWithData:firstWordBuffer encoding:_meta.encoding];
        lastKey = [[NSString alloc] initWithData:lastWordBuffer encoding:_meta.encoding];
		
		// 创建并添加关键块信息项
		WJXKeyInfoItem *keyInfoItem = [[WJXKeyInfoItem alloc] init];
		keyInfoItem.firstKey = firstKey;
		keyInfoItem.lastKey = lastKey;
		keyInfoItem.keyBlockPackSize = packSize;
		keyInfoItem.keyBlockPackAccumulator = kbPackSizeAccu;
		keyInfoItem.keyBlockUnpackSize = unpackSize;
		keyInfoItem.keyBlockUnpackAccumulator = kbUnpackSizeAccu;
		keyInfoItem.keyBlockEntriesNum = blockWordCount;
		keyInfoItem.keyBlockEntriesNumAccumulator = entriesCount;
		keyInfoItem.keyBlockInfoIndex = kbCount;
		
		[keyBlockInfoList addObject:keyInfoItem];
		
		// 更新累加器
		kbCount += 1;
		entriesCount += blockWordCount;
		kbPackSizeAccu += packSize;
		kbUnpackSizeAccu += unpackSize;
		
	}
	// 验证关键词块压缩大小是否与头部信息一致
	NSAssert(kbPackSizeAccu, @"关键词块压缩大小与头部信息不一致");
	return [keyBlockInfoList copy];
}

- (void)readKeyBlocks {
    _keyBlockStartOffset = _keyBlockInfoEndOffset;
    NSMutableArray<WJXKeyWordItem *> *keyBlockList = [NSMutableArray array];
    NSUInteger kbStartOffset = _keyBlockStartOffset;
    
    for (NSUInteger idx = 0; idx < _keyInfoList.count; idx++) {
        WJXKeyInfoItem *keyInfoItem = _keyInfoList[idx];
        NSUInteger packSize = keyInfoItem.keyBlockPackSize;
        NSUInteger unpackSize = keyInfoItem.keyBlockUnpackSize;
        
        NSUInteger start = kbStartOffset;
        NSAssert(start == keyInfoItem.keyBlockPackAccumulator + _keyBlockStartOffset, @"偏移量应该相等");
        
        // 读取压缩的关键词块数据
        NSData *kbCompBuff = [_scanner readBufferFromOffset: start length:packSize];
        // 解压关键词块
        NSData *keyBlock = [kbCompBuff wjx_unpackKeyBlock:unpackSize];
        
        // 拆分关键词块
        NSArray<WJXKeyWordItem *> *splitKeyBlock = [self splitKeyBlock:keyBlock keyBlockIdx:idx];
        
        // 如果已有关键词，设置前一个关键词的结束偏移量
        if (keyBlockList.count > 0 && keyBlockList.lastObject.recordEndOffset == -1) {
            keyBlockList.lastObject.recordEndOffset = splitKeyBlock.firstObject.recordStartOffset;
        }
        
        // 添加拆分后的关键词到列表
        [keyBlockList addObjectsFromArray:splitKeyBlock];
        
        // 更新偏移量
        kbStartOffset += packSize;
    }
    // 设置最后一个关键词的结束偏移量
    if (keyBlockList.count > 0 && keyBlockList.lastObject.recordEndOffset == -1) {
        keyBlockList.lastObject.recordEndOffset = -1; // 最后一个关键词
    }
    
    // 验证关键词数量是否与头部信息一致
    NSAssert(keyBlockList.count == _keyHeader.keywordNum, @"关键词列表长度: %lu 应该等于关键词条目数: %lu", (unsigned long)keyBlockList.count, (unsigned long)_keyHeader.keywordNum);
    
    // 计算关键词块结束偏移量
    _keyBlockEndOffset = _keyBlockStartOffset + _keyHeader.keywordBlockPackedSize;
    
    // 保存关键词列表
    _keywordList = keyBlockList;
}


/**
 * 读取记录头信息
 */
- (void)readRecordHeader {
    _recordHeaderStartOffset = _keyBlockEndOffset;
    
    // 根据版本确定记录头长度
    NSUInteger recordHeaderLen = (_meta.version >= 2.0) ? 4 * 8 : 4 * 4;
    _recordHeaderEndOffset = _recordHeaderStartOffset + recordHeaderLen;
    
    // 读取记录头数据
    NSData *recordHeaderBuffer = [_scanner readBufferFromOffset:_recordHeaderStartOffset length:recordHeaderLen];
    
    NSUInteger offset = 0;
    // 读取记录块数量
    NSData *recordBlocksNumData = [recordHeaderBuffer subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    NSUInteger recordBlocksNum = [recordBlocksNumData wjx_b2n];
    
    offset += _meta.numWidth;
    // 读取条目数量
    NSData *entriesNumData = [recordHeaderBuffer subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    NSUInteger entriesNum = [entriesNumData wjx_b2n];
    NSAssert(entriesNum == _keyHeader.keywordNum, @"条目数量应该等于关键词数量");
    
    offset += _meta.numWidth;
    // 读取记录信息压缩大小
    NSData *recordInfoCompSizeData = [recordHeaderBuffer subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    NSUInteger recordInfoCompSize = [recordInfoCompSizeData wjx_b2n];
    
    offset += _meta.numWidth;
    // 读取记录块压缩大小
    NSData *recordBlockCompSizeData = [recordHeaderBuffer subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
    NSUInteger recordBlockCompSize = [recordBlockCompSizeData wjx_b2n];
    
    // 保存记录头信息
    _recordHeader.recordBlocksNum = recordBlocksNum;
    _recordHeader.entriesNum = entriesNum;
    _recordHeader.recordInfoCompSize = recordInfoCompSize;
    _recordHeader.recordBlockCompSize = recordBlockCompSize;
    
}



/**
 * 读取记录信息列表
 */
- (void)readRecordInfos {
    _recordInfoStartOffset = _recordHeaderEndOffset;
    
    // 读取记录信息缓冲区
    NSData *recordInfoBuff = [_scanner readBufferFromOffset:_recordInfoStartOffset length:_recordHeader.recordInfoCompSize];
    
    /**
     * 记录块信息列表:
     * [{
     *   packSize: 压缩大小
     *   packAccumulateOffset: 压缩累计偏移量
     *   unpackSize: 解压后大小,
     *   unpackAccumulatorOffset: 解压后累计偏移量
     * }]
     * 注意: 每个记录块将包含多个条目
     */
    NSMutableArray<WJXRecordInfo *> *recordInfoList = [NSMutableArray array];
    NSUInteger offset = 0;
    NSUInteger compressedAdder = 0;
    NSUInteger decompressionAdder = 0;
    
    for (NSUInteger i = 0; i < _recordHeader.recordBlocksNum; i++) {
        // 读取压缩大小
        NSData *packSizeData = [recordInfoBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
        NSUInteger packSize = [packSizeData wjx_b2n];
        offset += _meta.numWidth;
        
        // 读取解压后大小
        NSData *unpackSizeData = [recordInfoBuff subdataWithRange:NSMakeRange(offset, _meta.numWidth)];
        NSUInteger unpackSize = [unpackSizeData wjx_b2n];
        offset += _meta.numWidth;
        
        // 创建记录信息对象
        WJXRecordInfo *recordInfo = [[WJXRecordInfo alloc] init];
        recordInfo.packSize = packSize;
        recordInfo.packAccumulateOffset = compressedAdder;
        recordInfo.unpackSize = unpackSize;
        recordInfo.unpackAccumulatorOffset = decompressionAdder;
        
        [recordInfoList addObject:recordInfo];
        
        // 累加偏移量
        compressedAdder += packSize;
        decompressionAdder += unpackSize;
    }
    
    // 断言检查
    NSAssert(offset == _recordHeader.recordInfoCompSize, @"记录信息偏移量应等于记录信息压缩大小");
    NSAssert(compressedAdder == _recordHeader.recordBlockCompSize, @"压缩累计偏移量应等于记录块压缩大小");
    
    // 保存记录信息列表
    _recordInfoList = recordInfoList;
    
    // 为最后一个关键词设置结束偏移量
    if (_keywordList.count > 0) {
        WJXRecordInfo *lastRecordInfo = recordInfoList.lastObject;
        WJXKeyWordItem *lastKeyword = _keywordList.lastObject;
        lastKeyword.recordEndOffset = lastRecordInfo.unpackAccumulatorOffset + lastRecordInfo.unpackSize;
    }
    
    // 设置记录信息结束偏移量
    _recordInfoEndOffset = _recordInfoStartOffset + _recordHeader.recordInfoCompSize;
    
    // 设置记录块起始偏移量（避免用户不调用解码记录块方法）
    _recordBlockStartOffset = _recordInfoEndOffset;
}





/**
 * 拆分关键词块
 * @param keyBlock 关键词块数据
 * @param keyBlockIdx 关键词块索引
 * @return 关键词项数组
 */
- (NSArray<WJXKeyWordItem *> *)splitKeyBlock:(NSData *)keyBlock keyBlockIdx:(NSUInteger)keyBlockIdx {
    // 确定宽度：UTF-16或MDD文件使用2字节宽度，否则使用1字节
    NSUInteger width = (_meta.encoding == NSUTF16StringEncoding || [_meta.ext isEqualToString:@"mdd"]) ? 2 : 1;
    NSMutableArray<WJXKeyWordItem *> *keyList = [NSMutableArray array];
    
    // 从关键词块开始解析
    NSUInteger keyStartIndex = 0;
    while (keyStartIndex < keyBlock.length) {
        // 读取含义偏移量
        NSUInteger meaningOffset = 0;
        NSData *meaningOffsetBuff = [keyBlock subdataWithRange:NSMakeRange(keyStartIndex, _meta.numWidth)];
        meaningOffset = [meaningOffsetBuff wjx_b2n];
        
        NSInteger keyEndIndex = -1;
        
        // 查找关键词结束位置（以0或0 0结尾）
        const uint8_t *bytes = [keyBlock bytes];
        NSUInteger i = keyStartIndex + _meta.numWidth;
        while (i < keyBlock.length) {
            if ((width == 1 && bytes[i] == 0) || 
                (width == 2 && bytes[i] == 0 && bytes[i + 1] == 0)) {
                keyEndIndex = i;
                break;
            }
            i += width;
        }
        
        // 如果没有找到结束位置，退出循环
        if (keyEndIndex == -1) {
            break;
        }
        
        // 提取关键词文本
        NSData *keyTextBuffer = [keyBlock subdataWithRange:NSMakeRange(keyStartIndex + _meta.numWidth, keyEndIndex - (keyStartIndex + _meta.numWidth))];
        NSString *keyText = [[NSString alloc] initWithData:keyTextBuffer encoding:_meta.encoding];
        
        // 如果已有关键词，设置前一个关键词的结束偏移量
        if (keyList.count > 0) {
            keyList[keyList.count - 1].recordEndOffset = meaningOffset;
        }
        
        // 创建并添加新的关键词项
        WJXKeyWordItem *keyWordItem = [[WJXKeyWordItem alloc] init];
        keyWordItem.recordStartOffset = meaningOffset;
        keyWordItem.keyText = keyText;
        keyWordItem.keyBlockIdx = keyBlockIdx;
        keyWordItem.recordEndOffset = -1;
        
        [keyList addObject:keyWordItem];
        keyStartIndex = keyEndIndex + width;
    }
    
    return [keyList copy];
}

- (BOOL)isKeyCaseSensitive {
    if (self.options.isCaseSensitive) {
        return YES;
    }
    
    NSString *caseSensitiveValue = self.header[@"isCaseSensitive"];
    if (caseSensitiveValue) {
        return [caseSensitiveValue wjx_isTrue];
    }
    return NO;
}


- (BOOL)isStripKey {
    if (self.options.isStripKey) {
        return YES;
    }
    
    NSString *stripKeyValue = self.header[@"StripKey"];
    if (stripKeyValue) {
        return [stripKeyValue wjx_isTrue];
    }
    return NO;
}

- (NSRegularExpression *)getStripKeyRegexForExt:(NSString *)ext {    
    // 根据文件扩展名返回对应的正则表达式字符串
    NSString *regexPattern = nil;
    
    if ([ext isEqualToString:@"mdx"]) {
        regexPattern = @"[().,\\-&、 '/@_$\\!]()";
    } else {
        regexPattern = @"([.][^.]*$)|[()., '/@]";
    }
    
    // 创建并返回正则表达式对象
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                          options:0
                                                                            error:&error];
    if (error) {
        NSLog(@"正则表达式创建失败: %@", error);
        return nil;
    }
    
    return regex;
}



@end

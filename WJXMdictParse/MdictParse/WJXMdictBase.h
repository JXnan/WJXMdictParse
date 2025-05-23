
#import <Foundation/Foundation.h>
#import "WJXFileScanner.h"
#import "WJXMdictMeta.h"
#import "WJXMdictOptions.h"
#import "WJXKeyHeader.h"
#import "WJXKeyInfoItem.h"
#import "WJXRecordHeader.h"
#import "WJXRecordInfo.h"

@interface WJXMdictBase : NSObject

// 文件扫描器
@property(nonatomic, strong) WJXFileScanner *scanner;

// MDX元信息
@property(nonatomic, strong) WJXMdictMeta *meta;

// 配置选项
@property(nonatomic, strong) WJXMdictOptions *options;

// 头部信息相关
@property(nonatomic, strong) NSMutableDictionary *header;

// 关键词头部信息
@property(nonatomic, strong) WJXKeyHeader *keyHeader;

// 关键词块信息列表
@property(nonatomic, copy) NSArray<WJXKeyInfoItem *> *keyInfoList;

// 关键词列表
@property(nonatomic, strong) NSMutableArray *keywordList;

// 记录头部信息
@property(nonatomic, strong) WJXRecordHeader *recordHeader;

// 记录信息列表
@property(nonatomic, strong) NSArray<WJXRecordInfo *> *recordInfoList;

// 记录块数据列表
@property(nonatomic, strong) NSMutableArray *recordBlockDataList;

// recordBlock start offset
@property(nonatomic, assign) NSUInteger recordBlockStartOffset;

- (instancetype)initWithFilename:(NSString *)filename
						passcode:(NSString *)passcode
						 options:(WJXMdictOptions *)options;

- (NSComparisonResult)comp:(NSString *)word1 withWord2:(NSString *)word2;

/**
 * 处理关键词，移除特殊字符
 * @param key 关键词
 * @return 处理后的关键词
 */
- (NSString *)strip:(NSString *)key;
@end

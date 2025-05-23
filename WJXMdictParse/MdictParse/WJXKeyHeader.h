#import <Foundation/Foundation.h>

/**
 * 字典关键头部结构
 */
@interface WJXKeyHeader : NSObject

/**
 * 关键词块数量
 */
@property(nonatomic, assign) NSUInteger keywordBlocksNum;

/**
 * 关键词数量
 */
@property(nonatomic, assign) NSUInteger keywordNum;

/**
 * 关键信息解压后大小
 */
@property(nonatomic, assign) NSUInteger keyInfoUnpackSize;

/**
 * 关键信息压缩后大小
 */
@property(nonatomic, assign) NSUInteger keyInfoPackedSize;

/**
 * 关键词块压缩后大小
 */
@property(nonatomic, assign) NSUInteger keywordBlockPackedSize;

@end

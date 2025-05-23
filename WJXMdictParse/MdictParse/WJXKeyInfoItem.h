#import <Foundation/Foundation.h>

/**
 * 字典关键头部结构
 */
@interface WJXKeyInfoItem : NSObject

/**
 * 第一个关键词
 */
@property(nonatomic, strong) NSString *firstKey;

/**
 * 最后一个关键词
 */
@property(nonatomic, strong) NSString *lastKey;

/**
 * 关键词块压缩大小
 */
@property(nonatomic, assign) NSInteger keyBlockPackSize;

/**
 * 关键词块压缩累加器
 */
@property(nonatomic, assign) NSInteger keyBlockPackAccumulator;

/**
 * 关键词块解压大小
 */
@property(nonatomic, assign) NSInteger keyBlockUnpackSize;

/**
 * 关键词块解压累加器
 */
@property(nonatomic, assign) NSInteger keyBlockUnpackAccumulator;

/**
 * 关键词块条目数量
 */
@property(nonatomic, assign) NSInteger keyBlockEntriesNum;

/**
 * 关键词块条目数量累加器
 */
@property(nonatomic, assign) NSInteger keyBlockEntriesNumAccumulator;

/**
 * 关键词块信息索引
 */
@property(nonatomic, assign) NSInteger keyBlockInfoIndex;

@end

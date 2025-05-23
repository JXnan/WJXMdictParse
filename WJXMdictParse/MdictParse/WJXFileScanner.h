
#import <Foundation/Foundation.h>

@interface WJXFileScanner : NSObject



/**
 * 初始化文件扫描器
 * @param filename 文件路径
 */
- (instancetype)initWithFilename:(NSString *)filename;

/**
 * 关闭文件
 */
- (void)close;

/**
 * 从指定偏移量读取指定长度的数据
 * @param offset 文件中的偏移量
 * @param length 要读取的数据长度
 * @return 读取的数据
 */
- (NSData *)readBufferFromOffset:(NSUInteger)offset length:(NSUInteger)length;

/**
 * 从指定偏移量读取指定长度的数字数据
 * @param offset 文件中的偏移量
 * @param length 要读取的数据长度
 * @return 读取的数据视图
 */
- (NSData *)readNumberFromOffset:(NSUInteger)offset length:(NSUInteger)length;

@end


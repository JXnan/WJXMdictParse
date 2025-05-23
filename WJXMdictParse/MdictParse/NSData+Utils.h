
#import <Foundation/Foundation.h>

@interface NSData (Utils)
/**
 * 将NSData转换为无符号整数
 * @return 转换后的无符号整数
 */
- (NSUInteger)wjx_b2n;

- (NSData *)wjx_mdxDecrypt;

- (NSData *)wjx_unpackKeyBlock:(NSUInteger)unpackSize;

- (NSData *)wjx_lzo1xDecompress:(NSUInteger)unpackSize;

- (NSData *)wjx_zlibDecode:(NSUInteger)unpackSize;

- (NSString *)wjx_hexString;

@end

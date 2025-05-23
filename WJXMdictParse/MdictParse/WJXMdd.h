//
//  WJXMdd.h
//  XDSReaderKitDemo
//
//  Created by WangJiaxin on 2025/5/21.
//

#import "WJXMdict.h"

NS_ASSUME_NONNULL_BEGIN

@interface WJXMdd : WJXMdict


/**
 * 定位资源键
 * @param resourceKey 资源键
 * @returns 键文本和定义
 */
- (NSData *)locateResourceKey:(NSString *)resourceKey;

@end

NS_ASSUME_NONNULL_END

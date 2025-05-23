//
//  WJXMdd.m
//  XDSReaderKitDemo
//
//  Created by WangJiaxin on 2025/5/21.
//

#import "WJXMdd.h"

@implementation WJXMdd

/**
 * 定位资源键
 * @param resourceKey 资源键
 * @returns 键文本和定义
 */
- (NSData *)locateResourceKey:(NSString *)resourceKey {
    id item = [self lookupKeyBlockByWord:resourceKey isAssociate:NO];
    if (!item) {
        return nil;
    }
    
    NSData *meaningBuff = [self lookupRecordByKeyBlock:item];
    return meaningBuff;
  
}



@end

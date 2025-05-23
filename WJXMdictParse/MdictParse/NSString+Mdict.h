

#import <Foundation/Foundation.h>

@interface NSString (Mdict)
+ (NSDictionary *)wjx_parseHeader:(NSString *)headerText;

- (NSString *)wjx_unescapeEntities;

- (BOOL)wjx_isTrue;

/**
 * 计算两个字符串之间的 Levenshtein 距离
 * @param otherString 要比较的字符串
 * @return Levenshtein 距离值
 */
- (NSInteger)wjx_levenshteinDistanceTo:(NSString *)otherString;
@end

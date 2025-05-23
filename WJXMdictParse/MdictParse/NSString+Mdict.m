

#import "NSString+Mdict.h"

/**
 * 返回三个数字中的最小值
 * @param a 第一个数字
 * @param b 第二个数字
 * @param c 第三个数字
 * @return 三个数字中的最小值
 */
NSInteger tripleMin(NSInteger a, NSInteger b, NSInteger c) {
    NSInteger temp = (a < b) ? a : b;
    return (temp < c) ? temp : c;
}


@implementation NSString (Mdict)

+ (NSDictionary *)wjx_parseHeader:(NSString *)headerText {
    NSMutableDictionary *headerAttr = [NSMutableDictionary dictionary];

    // 使用正则表达式匹配 key="value"
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)=\"((.|\\r|\\n)*?)\"" options:0 error:&error];

    if (error) {
        NSLog(@"Regex error: %@", error);
        return @{};
    }

    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:headerText options:0 range:NSMakeRange(0, headerText.length)];

    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges >= 3) {
            NSString *key = [headerText substringWithRange:[match rangeAtIndex:1]];
            NSString *value = [headerText substringWithRange:[match rangeAtIndex:2]];
            
            // 这里可以实现自定义 unescapeEntities，如果没有特殊字符也可以跳过
            NSString *unescapedValue = [value wjx_unescapeEntities] ?: value;
            
            headerAttr[key] = unescapedValue;
        }
    }

    // 处理 StyleSheet 字段
    id styleSheetRaw = headerAttr[@"StyleSheet"];
    if ([styleSheetRaw isKindOfClass:[NSString class]]) {
        NSArray<NSString *> *lines = [styleSheetRaw componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSMutableDictionary *styleSheetDict = [NSMutableDictionary dictionary];

        for (NSUInteger i = 0; i + 2 < lines.count; i += 3) {
            NSString *key = lines[i];
            NSString *value1 = lines[i + 1];
            NSString *value2 = lines[i + 2];
            if (key.length > 0) {
                styleSheetDict[key] = @[value1, value2];
            }
        }

        headerAttr[@"StyleSheet"] = styleSheetDict;
    }

    return [headerAttr copy];
}

- (NSString *)wjx_unescapeEntities {
    if (!self) return @"";

    NSMutableString *result = [self mutableCopy];

    [result replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0, result.length)];

    return [result copy];
}

/**
 * 检查字符串是否表示真值
 * @return 如果字符串表示真值则返回YES，否则返回NO
 */
- (BOOL)wjx_isTrue {
    if (!self) return NO;
    
    NSString *lowercaseStr = [self lowercaseString];
    return [lowercaseStr isEqualToString:@"yes"] || [lowercaseStr isEqualToString:@"true"];
}

/**
 * 计算两个字符串之间的 Levenshtein 距离
 * @param otherString 要比较的字符串
 * @return Levenshtein 距离值
 */
- (NSInteger)wjx_levenshteinDistanceTo:(NSString *)otherString {
    // 处理空字符串情况
    if (!self || self.length == 0) {
        return otherString ? otherString.length : 0;
    }
    
    if (!otherString || otherString.length == 0) {
        return self.length;
    }
    
    NSUInteger m = self.length;
    NSUInteger n = otherString.length;
    
    // 创建动态规划数组
    NSMutableArray<NSMutableArray<NSNumber *> *> *dp = [NSMutableArray arrayWithCapacity:m + 1];
    
    // 初始化dp数组
    for (NSUInteger i = 0; i <= m; i++) {
        NSMutableArray<NSNumber *> *row = [NSMutableArray arrayWithCapacity:n + 1];
        for (NSUInteger j = 0; j <= n; j++) {
            [row addObject:@0];
        }
        [dp addObject:row];
    }
    
    // 设置边界条件
    for (NSUInteger i = 0; i <= m; i++) {
        dp[i][0] = @(i);
    }
    
    for (NSUInteger j = 0; j <= n; j++) {
        dp[0][j] = @(j);
    }
    
    // 填充dp数组
    for (NSUInteger i = 1; i <= m; i++) {
        for (NSUInteger j = 1; j <= n; j++) {
            if ([self characterAtIndex:i-1] == [otherString characterAtIndex:j-1]) {
                dp[i][j] = dp[i-1][j-1];
            } else {
                NSInteger deletion = [dp[i-1][j] integerValue] + 1;
                NSInteger insertion = [dp[i][j-1] integerValue] + 1;
                NSInteger substitution = [dp[i-1][j-1] integerValue] + 1;
                
                // 取三者最小值
                NSInteger minValue = deletion < insertion ? deletion : insertion;
                minValue = minValue < substitution ? minValue : substitution;
                
                dp[i][j] = @(minValue);
            }
        }
    }
    
    return [dp[m][n] integerValue];
}



@end

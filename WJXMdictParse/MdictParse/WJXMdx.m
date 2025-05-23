//
//  WJXMdx.m
//  XDSReaderKitDemo
//
//  Created by WangJiaxin on 2025/5/20.
//

#import "WJXMdx.h"
#import "NSString+Mdict.h"
#import "WJXFuzzyWord.h"

@implementation WJXMdx

/**
 * 查找单词定义
 * @param word 要查找的单词
 * @return 单词定义或nil
 */
- (NSString *)lookup:(NSString *)word {
    // 查找关键词项
    WJXKeyWordItem *keyWordItem = [self lookupKeyBlockByWord:word isAssociate:NO];
    
    // 如果没有找到关键词项，返回包含原词但定义为nil的字典
    if (!keyWordItem) {
        return nil;
    }
    
    // 查找记录
    NSData *def = [self lookupRecordByKeyBlock:keyWordItem];
    
    // 如果没有找到定义，返回包含原词但定义为nil的字典
    if (!def) {
        return nil;
    }
    
    // 解码定义内容并返回结果
    NSString *definition = [[NSString alloc] initWithData:def encoding:self.meta.encoding];
    
    return definition;
}


/**
 * 搜索以指定前缀开头的词条
 * @param prefix 要搜索的前缀
 * @return 以该前缀开头的关键词项数组
 */
- (NSArray<WJXKeyWordItem *> *)prefix:(NSString *)prefix {
    // 获取关联词列表
    NSArray<WJXKeyWordItem *> *keywordList = [self associate:prefix];
    
    // 过滤出以前缀开头的词条
    NSMutableArray<WJXKeyWordItem *> *result = [NSMutableArray array];
    for (WJXKeyWordItem *item in keywordList) {
        if ([item.keyText hasPrefix:prefix]) {
            [result addObject:item];
        }
    }
    
    return result;
}

/**
 * 搜索匹配的关联词列表
 * @param phrase 要关联搜索的词语
 * @return 匹配的关键词项数组
 */
- (NSArray<WJXKeyWordItem *> *)associate:(NSString *)phrase {
    // 查找关键词块
    WJXKeyWordItem *keyBlockItem = [self lookupKeyBlockByWord:phrase isAssociate:YES];
    
    // 如果没有找到关键词块，返回空数组
    if (!keyBlockItem) {
        return @[];
    }
    
    // 过滤出与找到的关键词块索引相同的所有关键词
    NSMutableArray<WJXKeyWordItem *> *result = [NSMutableArray array];
    for (WJXKeyWordItem *keyword in self.keywordList) {
        if (keyword.keyBlockIdx == keyBlockItem.keyBlockIdx) {
            [result addObject:keyword];
        }
    }
    
    return result;
}

/**
 * 根据编辑距离推荐短语
 * @param phrase 搜索短语
 * @param distance 编辑距离
 * @return 推荐列表
 */
- (NSArray<WJXKeyWordItem *> *)suggest:(NSString *)phrase distance:(NSInteger)distance {
    // 检查编辑距离范围
    if (distance < 0 || distance > 5) {
        NSLog(@"编辑距离应该在0到5的范围内");
        return @[];
    }
    
    // 获取关联词列表
    NSArray<WJXKeyWordItem *> *keywordList = [self associate:phrase];
    NSMutableArray<WJXKeyWordItem *> *suggestList = [NSMutableArray array];
    
    // 遍历关键词列表，计算编辑距离
    for (WJXKeyWordItem *item in keywordList) {
        NSString *key = [self strip:item.keyText];
        NSInteger ed = [key wjx_levenshteinDistanceTo:[self strip:phrase]];
        if (ed <= distance) {
            [suggestList addObject:item];
        }
    }
    
    return suggestList;
}

/**
 * 获取关键词的定义
 * @param keywordItem 关键词项
 * @return 包含关键词文本和定义的字典
 */
- (NSString *)fetchDefinition:(WJXKeyWordItem *)keywordItem {
    // 查找关键词块对应的记录
    NSData *def = [self lookupRecordByKeyBlock:keywordItem];
    
    // 如果没有找到定义，返回只包含关键词文本的字典
    if (!def) {
        return nil;
    }
    
    // 解码定义并返回包含关键词文本和定义的字典
	return [[NSString alloc] initWithData:def encoding:self.meta.encoding];
}

/**
 * 模糊搜索关键词列表
 * @param word 搜索词
 * @param fuzzySize 模糊词大小
 * @param edGap 编辑距离
 * @return 模糊词列表
 */
- (NSArray<WJXFuzzyWord *> *)fuzzySearch:(NSString *)word fuzzySize:(NSInteger)fuzzySize edGap:(NSInteger)edGap {
    NSMutableArray<WJXFuzzyWord *> *fuzzyWords = [NSMutableArray array];
    
    // 获取关联词列表
    NSArray<WJXKeyWordItem *> *keywordList = [self associate:word];
    
    // 遍历关键词列表，计算编辑距离
    for (WJXKeyWordItem *item in keywordList) {
        NSString *key = [self strip:item.keyText];
        NSInteger ed = [key wjx_levenshteinDistanceTo:[self strip:word]];
        if (ed <= edGap) {
            WJXFuzzyWord *fuzzyWord = [[WJXFuzzyWord alloc] init];
            fuzzyWord.keyText = item.keyText;
            fuzzyWord.keyBlockIdx = item.keyBlockIdx;
            fuzzyWord.ed = ed;
            [fuzzyWords addObject:fuzzyWord];
        }
    }
    
    // 按编辑距离排序
    [fuzzyWords sortUsingComparator:^NSComparisonResult(WJXFuzzyWord *a, WJXFuzzyWord *b) {
        if (a.ed < b.ed) {
            return NSOrderedAscending;
        } else if (a.ed > b.ed) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // 截取指定大小的列表
    if (fuzzyWords.count > fuzzySize) {
        return [fuzzyWords subarrayWithRange:NSMakeRange(0, fuzzySize)];
    }
    
    return fuzzyWords;
}






@end

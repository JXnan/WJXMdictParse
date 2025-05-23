//
//  WJXMdx.h
//  XDSReaderKitDemo
//
//  Created by WangJiaxin on 2025/5/20.
//

#import "WJXMdict.h"

NS_ASSUME_NONNULL_BEGIN

@interface WJXMdx : WJXMdict

/**
 * 查找单词定义
 * @param word 要查找的单词
 * @return 单词定义或nil
 */
- (NSString *)lookup:(NSString *)word;

/**
 * 搜索以指定前缀开头的词条
 * @param prefix 要搜索的前缀
 * @return 以该前缀开头的关键词项数组
 */
- (NSArray<WJXKeyWordItem *> *)prefix:(NSString *)prefix;

/**
 * 根据编辑距离推荐短语
 * @param phrase 搜索短语
 * @param distance 编辑距离
 * @return 推荐列表
 */
- (NSArray<WJXKeyWordItem *> *)suggest:(NSString *)phrase distance:(NSInteger)distance;

/**
 * 搜索匹配的关联词列表
 * @param phrase 要关联搜索的词语
 * @return 匹配的关键词项数组
 */
- (NSArray<WJXKeyWordItem *> *)associate:(NSString *)phrase;

@end

NS_ASSUME_NONNULL_END

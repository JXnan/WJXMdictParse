#import "WJXMdictBase.h"
#import "WJXKeyWordItem.h"

@interface WJXMdict : WJXMdictBase

- (instancetype)initWithFilename:(NSString *)fname options:(WJXMdictOptions *)options;

/**
 * 通过关键词查找关键词块
 * @param word 目标词语
 * @param isAssociate 是否为关联查询
 * @return 关键词项
 */
- (WJXKeyWordItem *)lookupKeyBlockByWord:(NSString *)word isAssociate:(BOOL)isAssociate;

/**
 * 通过关键词项查找记录含义
 * 关键词项的recordStartOffset指示记录块信息的位置
 * 使用记录块信息，我们可以获取recordBuffer，然后需要解密和解压
 * 使用解压后的recordBuffer，我们可以获取包含含义的整个块
 * 然后使用：
 *  const start = item.recordStartOffset - recordBlockInfo.unpackAccumulatorOffset;
 *  const end = item.recordEndOffset - recordBlockInfo.unpackAccumulatorOffset;
 *  最终含义的缓冲区是 unpackRecordBlockBuff[start, end]
 * @param item 关键词项
 * @return 记录含义的数据
 */
- (NSData *)lookupRecordByKeyBlock:(WJXKeyWordItem *)item;

@end

#import <Foundation/Foundation.h>

@interface WJXRecordHeader : NSObject
@property(nonatomic, assign) NSInteger recordBlocksNum;
@property(nonatomic, assign) NSInteger entriesNum;
@property(nonatomic, assign) NSInteger recordInfoCompSize;
@property(nonatomic, assign) NSInteger recordBlockCompSize;

@end

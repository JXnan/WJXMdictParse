#import <Foundation/Foundation.h>

@interface WJXKeyWordItem : NSObject

@property(nonatomic, assign) NSInteger recordStartOffset;
@property(nonatomic, assign) NSInteger recordEndOffset;
@property(nonatomic, copy) NSString *keyText;
@property(nonatomic, assign) NSInteger keyBlockIdx;

@end

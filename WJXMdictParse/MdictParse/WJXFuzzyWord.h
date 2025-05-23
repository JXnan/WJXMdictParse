//
//  WJXFuzzyWord.h
//  XDSReaderKitDemo
//
//  Created by WangJiaxin on 2025/5/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WJXFuzzyWord : NSObject
@property(nonatomic, assign) NSInteger recordStartOffset;
@property(nonatomic, assign) NSInteger recordEndOffset;
@property(nonatomic, copy) NSString *keyText;
@property(nonatomic, assign) NSInteger keyBlockIdx;
@property(nonatomic, assign) NSInteger ed;

@end

NS_ASSUME_NONNULL_END

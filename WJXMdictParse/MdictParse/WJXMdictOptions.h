
#import <Foundation/Foundation.h>

@interface WJXMdictOptions : NSObject

@property (nonatomic, copy) NSString *passcode;
@property (nonatomic, assign) BOOL debug;
@property (nonatomic, assign) BOOL resort;
@property (nonatomic, assign) BOOL isStripKey;
@property (nonatomic, assign) BOOL isCaseSensitive;
@property (nonatomic, assign) NSInteger encryptType;

+ (instancetype)defaultOptions;

@end

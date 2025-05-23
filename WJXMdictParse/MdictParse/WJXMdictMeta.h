#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WJXNumFmt) {
    kNumFmtUint8,
    kNumFmtUint16,
    kNumFmtUint32,
    kNumFmtUint64
};

@interface WJXMdictMeta : NSObject

@property (nonatomic, copy) NSString *fname;
@property (nonatomic, copy) NSString *passcode;
@property (nonatomic, copy) NSString *ext;
@property (nonatomic, assign) CGFloat version;
@property (nonatomic, assign) NSInteger numWidth;
@property (nonatomic, assign) WJXNumFmt numFmt;
@property (nonatomic, assign) NSStringEncoding encoding;

@property (nonatomic, assign) NSUInteger encrypt;

- (NSString *)encode:(NSData *)data;

@end

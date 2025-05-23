
#import "WJXMdictMeta.h"

@implementation WJXMdictMeta
    
    
- (instancetype)init {
    self = [super init];
    if (self) {
        _fname = @"";
        _passcode = @"mdx";
        _ext = @"";
        _version = 2.0;
        _numWidth = 4;
        _numFmt = kNumFmtUint32;
        _encoding = NSUTF8StringEncoding;
        _encrypt = 0;
    }
    return self;
}
- (NSString *)encode:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:self.encoding];
}

@end


#import "WJXMdictOptions.h"


@implementation WJXMdictOptions

+ (instancetype)defaultOptions {
    WJXMdictOptions *options = [[WJXMdictOptions alloc] init];
    options.passcode = nil;
    options.debug = NO;
    options.resort = YES;
    options.isStripKey = YES;
    options.isCaseSensitive = NO;
    options.encryptType = -1;
    return options;
}


@end


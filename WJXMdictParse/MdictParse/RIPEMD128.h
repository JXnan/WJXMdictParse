#import <Foundation/Foundation.h>


@interface RIPEMD128 : NSObject

+ (NSData *)ripemd128HashForData:(NSData *)data;

@end

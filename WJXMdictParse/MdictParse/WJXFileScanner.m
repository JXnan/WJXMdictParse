#import "WJXFileScanner.h"


@interface WJXFileScanner()

/**
 * 文件偏移量
 */
@property (nonatomic, assign) NSUInteger offset;

/**
 * 文件路径
 */
@property (nonatomic, copy) NSString *filepath;

/**
 * 文件句柄
 */
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation WJXFileScanner

- (instancetype)initWithFilename:(NSString *)filename {
    if (self = [super init]) {
        _filepath = [filename copy];
        _offset = 0;
        
        NSError *error = nil;
        _fileHandle = [NSFileHandle fileHandleForReadingFromURL:[NSURL fileURLWithPath:filename] error:&error];
        
        if (error || !_fileHandle) {
            NSLog(@"无法打开文件: %@, 错误: %@", filename, error);
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    if (_fileHandle) {
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
}

- (NSData *)readBufferFromOffset:(NSUInteger)offset length:(NSUInteger)length {
    @try {
        [_fileHandle seekToFileOffset:offset];
        NSData *data = [_fileHandle readDataOfLength:length];
        return data;
    } @catch (NSException *exception) {
        NSLog(@"读取文件数据失败: %@", exception);
        return [NSData data]; // 返回空数据
    }
}

- (NSData *)readNumberFromOffset:(NSUInteger)offset length:(NSUInteger)length {
    // 在Objective-C中，直接返回NSData，调用者可以根据需要解析为具体的数字类型
    return [self readBufferFromOffset:offset length:length];
}

@end
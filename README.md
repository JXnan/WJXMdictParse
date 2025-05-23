# WJXMdictParse

WJXMdictParse 是一个用于解析 Mdict 词典文件的 iOS 库。它支持解析 .mdx 和 .mdd 格式的词典文件。

## 功能特点

-   支持 .mdx 和 .mdd 格式的词典文件解析
-   提供简单易用的 API
-   支持模糊搜索
-   支持词典元数据读取

## 安装

### CocoaPods

```ruby
pod 'WJXMdictParse'
```

## 使用方法

```objective-c
#import <WJXMdictParse/WJXMdict.h>

// 初始化词典
WJXMdict *dict = [[WJXMdict alloc] initWithPath:@"path/to/dictionary.mdx"];

// 查询单词
[dict lookupWord:@"example" completion:^(NSString *result) {
    // 处理查询结果
}];
```

## 要求

-   iOS 9.0+
-   Xcode 11+

## 许可证

WJXMdictParse 使用 MIT 许可证。详见 LICENSE 文件。

[![GitHub issues](https://img.shields.io/github/issues/terasum/js-mdict.svg)](https://github.com/JXnan/WJXMdictParse/issues)
[![GitHub forks](https://img.shields.io/github/forks/terasum/js-mdict.svg)](https://github.com/JXnan/WJXMdictParse/network)
[![GitHub stars](https://img.shields.io/github/stars/terasum/js-mdict.svg)](https://github.com/JXnan/WJXMdictParse/stargazers)
[![GitHub license](https://img.shields.io/github/license/terasum/js-mdict.svg)](https://github.com/JXnan/WJXMdictParse/blob/develop/LICENSE)

mdict (\*.mdd \*.mdx) file reader based on [terasum/js-mdict](https://github.com/terasum/js-mdict) .

Thanks to [terasum](https://github.com/terasum/js-mdict) 、[fengdh](https://github.com/fengdh/mdict-js) and [jeka-kiselyov](https://github.com/jeka-kiselyov/mdict).
# WJXMdictParse

WJXMdictParse 是一个用于解析 Mdict 词典文件的 iOS 库。它支持解析 .mdx 和 .mdd 格式的词典文件。

## 功能特点

-   支持 .mdx 和 .mdd 格式的词典文件解析
-   提供简单易用的 API
-   支持模糊搜索

## 安装

### CocoaPods

```ruby
pod 'WJXMdictParse'
```

## 使用方法

```objective-c
#import <WJXMdictParse/WJXMdictParse.h>

// 初始化mdx文件查询
WJXMdx *mdx = [[WJXMdx alloc] initWithFilename:@"path/to/dictionary.mdx" options:nil];

// 查询单词
NSString *result = [mdx lookup:@"example"];

// 初始化mdd文件查询
WJXMdd *mdd = [[WJXMdd alloc] initWithFilename:@"path/to/dictionary.mdd" options:nil];
// 查询资源数据
NSData *result = [mdx locateResourceKey:@"example"];

// 可以通过keywordList了解mdd资源数据的key
NSArray *keyList = [mdd keywordList];
```

## 要求

-   iOS 12.0+
-   Xcode 15+

## 许可证

WJXMdictParse 使用 MIT 许可证。

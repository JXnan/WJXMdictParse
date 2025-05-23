//
//  ViewController.m
//  WJXMdictParse
//
//  Created by WangJiaxin on 2025/5/22.
//

#import "ViewController.h"
#import "WJXMdicParse.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) WKWebView *webView;

@property(nonatomic, strong) WJXMdd *mdd;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.height - 100)];
//    self.textView.backgroundColor = [UIColor whiteColor];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.height - 100)];
    self.webView.navigationDelegate = self;
    

    [self.view addSubview:self.webView];
    
    NSString * mdxPath = [[NSBundle mainBundle] pathForResource:@"Webster" ofType:@"mdx"];
    NSString * mddPath = [[NSBundle mainBundle] pathForResource:@"Webster" ofType:@"mdd"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:mdxPath]) {
        NSLog(@"文件不存在-- %@", mdxPath);
    }
    
    WJXMdx * dict = [[WJXMdx alloc] initWithFilename:mdxPath options:nil];
    self.mdd = [[WJXMdd alloc] initWithFilename:mddPath options:nil];
    NSString *str = [dict lookup:@"hi"];
    NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"dict" ofType:@"css"];
    NSString *cssContent = [NSString stringWithContentsOfFile:cssPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *html = [NSString stringWithFormat:@"<style>%@</style>%@", @"", str];
    
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];

//    NSAttributedString * attStr = [[NSAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil];
//    self.textView.attributedText = attStr;
    [self.webView loadHTMLString:html baseURL:nil];

}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    
    NSString * str = navigationAction.request.URL.absoluteString;
    NSString * mddStr = [self.mdd locateResourceKey:str];
    
    
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end

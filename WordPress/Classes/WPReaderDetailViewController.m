//
//  WPReaderDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 5/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPReaderDetailViewController.h"
#import "WPWebBridge.h"
#import "ReachabilityUtils.h"

@interface WPReaderDetailViewController ()

@property (nonatomic, strong) WPWebBridge *webBridge;

- (void)loadNextItem:(id)sender;
- (void)loadPreviousItem:(id)sender;
- (void)prepareViewForItem;

@end

@implementation WPReaderDetailViewController


@synthesize delegate, currentItem, webBridge;


- (void)dealloc
{
    self.webBridge.delegate = nil;
}

- (void)viewDidLoad {
    self.webBridge = [WPWebBridge bridge];
    self.webBridge.delegate = self;
    [super viewDidLoad];
    if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateHighlighted];
        
        UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        
        backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        
        btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
        
        [btn addTarget:self action:@selector(showLinkOptions) forControlEvents:UIControlEventTouchUpInside];
        
        self.optionsButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
    } else {
        self.optionsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                           target:self
                                                                           action:@selector(showLinkOptions)];
    }
    super.iPadNavBar.topItem.rightBarButtonItem = self.optionsButton;
    self.optionsButton.enabled = YES;
    self.navigationItem.rightBarButtonItem = self.optionsButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.detailContent = @"";
    [super viewWillAppear:animated];

    self.forwardButton.target = self;
    self.forwardButton.action = @selector(loadNextItem:);
    
    
    self.backButton.target = self;
    self.backButton.action = @selector(loadPreviousItem:);
    
    [self prepareViewForItem];

}

- (void)prepareViewForItem {
    if(self.currentItem != nil){
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.show_article_details(%@);", self.currentItem]];
        self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.current_item.title"];
    }
    
    self.forwardButton.enabled = [self.delegate detailController:self hasNextForItem:self.currentItem];
    self.backButton.enabled = [self.delegate detailController:self hasPreviousForItem:self.currentItem];

}

- (void)loadNextItem:(id)sender
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    self.currentItem = [self.delegate nextItemForDetailController:self];
    [self prepareViewForItem];
    
}

- (void)loadPreviousItem:(id)sender
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    self.currentItem = [self.delegate previousItemForDetailController:self];
    [self prepareViewForItem];
}

- (void)setTitle:(NSString *)title
{
    super.title = title;
    self.navigationItem.title = title;
    if (IS_IPAD) {
        self.iPadNavBar.topItem.title = title;
    }
}

- (BOOL)webView:(UIWebView *)view shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self.webBridge handlesRequest:request]) {
        return NO;
    }
    
    return [super webView:view shouldStartLoadWithRequest:request navigationType:navigationType];
    
}


@end

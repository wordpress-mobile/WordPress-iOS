//
//  WPReaderDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 5/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPReaderDetailViewController.h"


@interface WPReaderDetailViewController ()

- (void)loadNextItem:(id)sender;
- (void)loadPreviousItem:(id)sender;
- (void)prepareViewForItem;

@end

@implementation WPReaderDetailViewController


@synthesize delegate, currentItem;


- (void)dealloc
{
    self.currentItem = nil;
    [super dealloc];
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
    self.currentItem = [self.delegate nextItemForDetailController:self];
    [self prepareViewForItem];
    
}

- (void)loadPreviousItem:(id)sender
{
    self.currentItem = [self.delegate previousItemForDetailController:self];
    [self prepareViewForItem];
}

- (void)setViewTitle:(NSString *)title
{
    self.title = title;
    self.navigationItem.title = title;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    //Change title color on iOS 4
    if (![[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        UILabel *titleView = (UILabel *)self.navigationItem.titleView;
        if (!titleView) {
            titleView = [[UILabel alloc] initWithFrame:CGRectZero];
            titleView.backgroundColor = [UIColor clearColor];
            titleView.font = [UIFont boldSystemFontOfSize:20.0];
            titleView.shadowColor = [UIColor whiteColor];
            titleView.shadowOffset = CGSizeMake(0.0, 1.0);
            titleView.textColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0];
            
            self.navigationItem.titleView = titleView;
            [titleView release];
        }
        titleView.text = title;
        [titleView sizeToFit];
    }
}

@end

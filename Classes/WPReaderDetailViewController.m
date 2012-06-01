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
        self.navigationItem.title = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.current_item.title"];
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

@end

//
//  WPReaderDetailViewController.h
//  WordPress
//
//  Created by Beau Collins on 5/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPWebViewController.h"

@class WPReaderDetailViewController;

@protocol WPReaderDetailViewControllerDelegate <NSObject>

- (id)nextItemForDetailController:(WPReaderDetailViewController *)detailController;
- (id)previousItemForDetailController:(WPReaderDetailViewController *)detailController;
- (BOOL)detailController:(WPReaderDetailViewController *)detailController hasNextForItem:(id)item;
- (BOOL)detailController:(WPReaderDetailViewController *)detailController hasPreviousForItem:(id)item;

@end

@interface WPReaderDetailViewController : WPWebViewController

@property (nonatomic, weak) id<WPReaderDetailViewControllerDelegate> delegate;
@property (nonatomic, strong) id currentItem;

@end

//
//  ReaderPostsViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPRefreshViewController.h"
#import "PanelNavigationController.h"

@interface ReaderPostsViewController : WPRefreshViewController <NSFetchedResultsControllerDelegate, DetailViewDelegate>

@end

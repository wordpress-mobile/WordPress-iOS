/*
 * MediaBrowserViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import <UIKit/UIKit.h>
#import "MediaSearchFilterHeaderView.h"

@class Blog;

@interface MediaBrowserViewController : UIViewController <MediaSearchFilterDelegate, UISearchBarDelegate>

@property (nonatomic, strong) Blog *blog;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

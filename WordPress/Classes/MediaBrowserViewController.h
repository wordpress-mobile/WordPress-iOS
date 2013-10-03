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

@class Blog, AbstractPost;

@interface MediaBrowserViewController : UIViewController <MediaSearchFilterDelegate, UISearchBarDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (id)initWithPost:(AbstractPost*)aPost selectingMediaForPost:(BOOL)isSelectingMediaForPost;
- (id)initWithPost:(AbstractPost *)aPost;
- (id)initWithPost:(AbstractPost *)aPost settingFeaturedImage:(BOOL)isSettingFeaturedImage;

@end

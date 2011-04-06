//
//  QuickPhotoViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogSelectorButton.h"

#define QPVCBlogForQuickPhoto @"blogForQuickPhoto"

@interface QuickPhotoViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,BlogSelectorButtonDelegate> {
    
}

@property (nonatomic, retain) IBOutlet UIImageView *photoImageView;
@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) IBOutlet BlogSelectorButton *blogSelector;
@property (nonatomic, retain) UIBarButtonItem *postButtonItem;
@property (nonatomic, retain) UIImage *photo;

- (void)post;
- (void)cancel;
@end

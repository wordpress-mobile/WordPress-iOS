//
//  QuickPhotoViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPAsynchronousImageView.h"

#define QPVCBlogForQuickPhoto @"blogForQuickPhoto"

@interface QuickPhotoViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    
}

@property (nonatomic, retain) IBOutlet UIImageView *photoImageView;
@property (nonatomic, retain) IBOutlet WPAsynchronousImageView *blavatarImageView;
@property (nonatomic, retain) IBOutlet UILabel *blogTitleLabel;
@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) UIBarButtonItem *postButtonItem;
@property (nonatomic, retain) UIImage *photo;

- (IBAction)selectBlog;
- (void)post;
- (void)cancel;
@end

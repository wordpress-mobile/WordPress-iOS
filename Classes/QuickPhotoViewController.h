//
//  QuickPhotoViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogSelectorButton.h"
#import "WPProgressHUD.h"
#import "Post.h"
#import "QuickPicturePreviewView.h"
#import "BlogsViewController.h"
#import "WordPressAppDelegate.h"

#define QPVCBlogForQuickPhoto @"blogForQuickPhoto"

@interface QuickPhotoViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,BlogSelectorButtonDelegate,QuickPicturePreviewViewDelegate> {
	WordPressAppDelegate *appDelegate;
    Post *post;
    BlogsViewController *blogsViewController;
}

@property (nonatomic, retain) IBOutlet QuickPicturePreviewView *photoImageView;
@property (nonatomic, retain) IBOutlet UITextField *titleTextField;
@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) IBOutlet BlogSelectorButton *blogSelector;
@property (nonatomic, retain) UIBarButtonItem *postButtonItem;
@property (nonatomic, retain) UIImage *photo;
@property (nonatomic, retain) BlogsViewController *blogsViewController;
@property (nonatomic, assign) UIImagePickerControllerSourceType sourceType;

- (void)post;
- (void)cancel;
- (void)saveImage;
@end

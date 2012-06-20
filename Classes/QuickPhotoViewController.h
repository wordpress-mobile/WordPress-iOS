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
#import "WordPressAppDelegate.h"
#import "SidebarViewController.h"

#define QPVCBlogForQuickPhoto @"blogForQuickPhoto"

@class Blog;

@interface QuickPhotoViewController : UIViewController <UIPopoverControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BlogSelectorButtonDelegate, QuickPicturePreviewViewDelegate> {
	WordPressAppDelegate *appDelegate;
    Post *post;
    CGRect startingFrame;
    CGRect keyboardFrame;
    
    SidebarViewController *sidebarViewController;
    Blog *startingBlog;
}

@property (nonatomic, retain) IBOutlet QuickPicturePreviewView *photoImageView;
@property (nonatomic, retain) IBOutlet UITextField *titleTextField;
@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) IBOutlet BlogSelectorButton *blogSelector;
@property (nonatomic, retain) UIBarButtonItem *postButtonItem;
@property (nonatomic, retain) UIImage *photo;
@property (nonatomic, assign) UIImagePickerControllerSourceType sourceType;
@property (nonatomic, assign) BOOL isCameraPlus;
@property (nonatomic, retain) SidebarViewController *sidebarViewController;
@property (nonatomic, retain) Blog *startingBlog;

- (void)post;
- (void)cancel;
- (void)saveImage;

@end

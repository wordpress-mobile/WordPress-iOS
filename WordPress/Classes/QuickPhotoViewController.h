//
//  QuickPhotoViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogSelectorButton.h"
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

@property (nonatomic, strong) IBOutlet QuickPicturePreviewView *photoImageView;
@property (nonatomic, strong) IBOutlet UITextField *titleTextField;
@property (nonatomic, strong) IBOutlet UITextView *contentTextView;
@property (nonatomic, strong) IBOutlet BlogSelectorButton *blogSelector;
@property (nonatomic, strong) UIBarButtonItem *postButtonItem;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, assign) UIImagePickerControllerSourceType sourceType;
@property (nonatomic, assign) BOOL isCameraPlus;
@property (nonatomic, strong) SidebarViewController *sidebarViewController;
@property (nonatomic, strong) Blog *startingBlog;

- (void)post;
- (void)cancel;
- (void)saveImage;
- (void)dismiss;

@end

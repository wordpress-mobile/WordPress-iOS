//
//  BlogSelectorButton.h
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "BlogSelectorViewController.h"

#define kBlogSelectorQuickPhoto @"BlogSelectorQuickPhoto"

typedef enum {
    BlogSelectorButtonTypeDefault,
    BlogSelectorButtonTypeQuickPhoto
} BlogSelectorButtonType;

@class BlogSelectorButton;
@protocol BlogSelectorButtonDelegate <NSObject>
@optional
- (void)blogSelectorButtonWillBecomeActive:(BlogSelectorButton *)button;
- (void)blogSelectorButtonDidBecomeActive:(BlogSelectorButton *)button;
- (void)blogSelectorButtonWillBecomeInactive:(BlogSelectorButton *)button;
- (void)blogSelectorButtonDidBecomeInactive:(BlogSelectorButton *)button;
- (void)blogSelectorButton:(BlogSelectorButton *)button didSelectBlog:(Blog *)blog;
@end

@interface BlogSelectorButton : UIButton<BlogSelectorViewControllerDelegate> {
    UIImageView *blavatarImageView;
    UILabel *blogTitleLabel;
    UILabel *postToLabel;
    UIImageView *selectorImageView;
    BOOL active;
    BlogSelectorViewController *selectorViewController;
    BlogSelectorButtonType blogType;
    CGRect normalFrame;
}
@property (nonatomic, strong) Blog *activeBlog;
@property (nonatomic, weak) id<BlogSelectorButtonDelegate> delegate;

- (void)loadBlogsForType:(BlogSelectorButtonType)aType;

@end

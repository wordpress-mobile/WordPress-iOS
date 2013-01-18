//
//  PostViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPostViewController.h"
#import "Post.h"

@interface PostViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIWebViewDelegate, UIActionSheetDelegate> {
    BOOL isShowingActionSheet;
}

@property (nonatomic, strong) IBOutlet UILabel *titleTitleLabel, *tagsTitleLabel, *categoriesTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel, *tagsLabel, *categoriesLabel;
@property (nonatomic, strong) IBOutlet UITextView *contentView;
@property (nonatomic, strong) IBOutlet UIWebView *contentWebView;
@property (nonatomic, strong) IBOutlet AbstractPost *apost;
@property (nonatomic, weak) Post *post;
@property (nonatomic, weak) Blog * blog;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)showModalEditor;
- (void)refreshUI;
- (void)checkForNewItem;
- (EditPostViewController *) getPostOrPageController: (AbstractPost *)revision;
- (void)showDeletePostActionSheet:(id)sender;
- (void)deletePost;
- (void)refreshUI;
- (NSString *)formatString:(NSString *)str;
- (void)showModalPreview;
- (void)dismissPreview;

@end

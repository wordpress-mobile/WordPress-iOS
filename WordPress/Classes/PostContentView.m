//
//  PostContentView.m
//  WordPress
//
//  Created by Eric Johnson on 2/27/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostContentView.h"
#import "AbstractPost.h"
#import "WPContentViewSubclass.h"
#import "WPStyleGuide.h"
#import "NSAttributedString+HTML.h"
#import "UIImage+Util.h"


const CGFloat RPVStatusVerticalPadding = 8.0f;

@interface PostContentView ()

@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, strong) UIButton *shareButton;

@end

@implementation PostContentView

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame showFullContent:showFullContent];
    if (self) {
        UIView *contentView = [self viewForFullContent];
        [self addSubview:contentView];
        
        UIButton *trashButton = [super addActionButtonWithImage:[UIImage imageNamed:@"icon-comments-trash"] selectedImage:[UIImage imageNamed:@"icon-comments-trash-active"]];
        trashButton.accessibilityLabel = NSLocalizedString(@"Move to trash", @"Spoken accessibility label.");
        [trashButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];

        UIButton *previewButton = [super addActionButtonWithImage:[UIImage imageNamed:@"icon-posts-preview"] selectedImage:[UIImage imageNamed:@"icon-posts-preview-active"]];
        previewButton.accessibilityLabel = NSLocalizedString(@"Mark as spam", @"Spoken accessibility label.");
        [previewButton addTarget:self action:@selector(previewAction:) forControlEvents:UIControlEventTouchUpInside];

        UIButton *shareButton = [super addActionButtonWithImage:[UIImage imageNamed:@"icon-posts-share-action"] selectedImage:[UIImage imageNamed:@"icon-posts-share-action-active"]];
        [shareButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        shareButton.accessibilityLabel = NSLocalizedString(@"Share post", @"Spoken accessibility label.");
        self.shareButton = shareButton;
    }
    return self;
}

- (void)configurePost:(AbstractPost *)post withWidth:(CGFloat)width {
    self.contentProvider = post;
    self.post = post;

    self.shareButton.hidden = !self.post.hasRemote;

    self.byView.hidden = YES;

    if (self.post.featuredImageURLForDisplay) {
        self.cellImageView.hidden = NO;
    }

    CGFloat contentWidth = width;
    if (IS_IPAD) {
        contentWidth = WPTableViewFixedWidth;
    }
    contentWidth -= RPVHorizontalInnerPadding * 2;

    self.titleLabel.attributedText = [[self class] titleAttributedStringForTitle:self.post.postTitle
                                                                 showFullContent:self.showFullContent
                                                                       withWidth:contentWidth];

    NSData *data = [[self.contentProvider contentForDisplay] dataUsingEncoding:NSUTF8StringEncoding];
    self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
    [self.textContentView relayoutText];
}

- (CGFloat)layoutAttributionAt:(CGFloat)yPosition {
    // We're not showing the attribution view for posts, so return the yPosition unchanged
    return yPosition;
}

- (void)refreshDate:(NSTimer *)timer {
    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }

    NSString *title = [dateFormatter stringFromDate:[self.contentProvider dateForDisplay]];
    [self.timeButton setTitle:title forState:UIControlStateNormal | UIControlStateDisabled];
}

- (void)shareAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveShareAction:)]) {
        [self.delegate postView:self didReceiveShareAction:sender];
    }
}

- (void)previewAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceivePreviewAction:)]) {
        [self.delegate postView:self didReceivePreviewAction:sender];
    }
}

- (void)deleteAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveDeleteAction:)]) {
        [self.delegate postView:self didReceiveDeleteAction:sender];
    }
}

@end

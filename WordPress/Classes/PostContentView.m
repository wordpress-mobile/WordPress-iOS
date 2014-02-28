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

@interface PostContentView ()

@property (nonatomic, strong) AbstractPost *post;

@end

@implementation PostContentView

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent {
    self = [super initWithFrame:frame showFullContent:showFullContent];
    if (self) {
        UIView *contentView = [self viewForFullContent];
        [self addSubview:contentView];
    }
    return self;
}

- (void)configurePost:(BasePost *)post withWidth:(CGFloat)width {
    self.contentProvider = post;
    self.post = (AbstractPost *)post;
    
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

@end

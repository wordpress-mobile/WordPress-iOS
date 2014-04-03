//
//  CommentView.m
//  WordPress
//
//  Created by Michael Johnston on 12/13/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CommentView.h"
#import "WPContentViewSubclass.h"
#import "UIImageView+Gravatar.h"
#import "NSAttributedString+HTML.h"

@implementation CommentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *contentView = [self viewForFullContent];
        [self addSubview:contentView];
    }
    return self;
}

- (void)configureContentView:(id<WPContentViewProvider>)contentProvider {
    [super configureContentView:contentProvider];
    
    NSString *avatarEmail = [contentProvider gravatarEmailForDisplay];
    NSURL *avatarURL = [contentProvider avatarURLForDisplay];
    UIImage *avatarPlaceholderImage = [UIImage imageNamed:@"gravatar"];
    
    // Use email if it exists, otherwise a direct URL
    if (avatarEmail) {
        [self.avatarImageView setImageWithGravatarEmail:avatarEmail fallbackImage:avatarPlaceholderImage];
    } else if (avatarURL) {
        [self.avatarImageView setImageWithURL:avatarURL placeholderImage:avatarPlaceholderImage];
    }
    
    NSString *commentHtml = [contentProvider contentForDisplay];
    if (!commentHtml) {
        return;
    }

    NSData *data = [commentHtml dataUsingEncoding:NSUTF8StringEncoding];
    self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
    [self.textContentView relayoutText];
}

- (void)layoutSubviews {
    [super layoutSubviews];    
}

@end

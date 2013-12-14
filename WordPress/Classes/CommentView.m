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
    
    [self.avatarImageView setImageWithGravatarEmail:[contentProvider gravatarEmailForDisplay] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
    
    NSString *partialHtml = [contentProvider contentForDisplay];
    NSString *fullHtml;
    
    // The comment content is...partly HTML. But not completely. For unknown reasons.
    if (partialHtml == nil) {
        fullHtml = [NSString stringWithFormat:@"<html><head></head><body><p>%@</p></body></html>", @"<br />"];
    } else {
        fullHtml = [NSString stringWithFormat:@"<html><head></head><body><p>%@</p></body></html>", [[partialHtml trim] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
    }

    NSData *data = [fullHtml dataUsingEncoding:NSUTF8StringEncoding];
    self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
    [self.textContentView relayoutText];
}

- (void)layoutSubviews {
    [super layoutSubviews];    
}

@end

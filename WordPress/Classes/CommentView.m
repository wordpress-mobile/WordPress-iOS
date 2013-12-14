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

@implementation CommentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)configureContentView:(id<WPContentViewProvider>)contentProvider {
    [super configureContentView:contentProvider];
    
    [self.avatarImageView setImageWithGravatarEmail:[contentProvider gravatarEmailForDisplay] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
}

@end

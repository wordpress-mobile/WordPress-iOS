//
//  NewCommentsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewCommentsTableViewCell.h"
#import "Comment.h"
#import "NSString+XMLExtensions.h"

@implementation NewCommentsTableViewCell

+ (BOOL)showGravatarImage {
    return YES;
}

+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    // combine author and title
    NSString *author = [contentProvider authorForDisplay];
    NSString *postTitle = [contentProvider titleForDisplay];
    NSString *content = [contentProvider contentPreviewForDisplay];
    if (!(postTitle.length > 0)) {
        postTitle = NSLocalizedString(@"(No Title)", nil);
    }
    
    NSMutableAttributedString *attributedPostTitle = [[NSMutableAttributedString alloc] initWithString:author attributes:[[self class] titleAttributesBold]];
    [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" on ", @"") attributes:[[self class] titleAttributes]]];
    [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:postTitle attributes:[[self class] titleAttributesBold]]];
    if (content.length > 0) {
        [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@": %@", content] attributes:[[self class] titleAttributes]]];
    }

    return attributedPostTitle;
}

@end


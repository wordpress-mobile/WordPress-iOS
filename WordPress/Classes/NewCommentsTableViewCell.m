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
    
    if (!(postTitle.length > 0)) {
        postTitle = NSLocalizedString(@"(No Title)", nil);
    }
    postTitle = [NSLocalizedString(@"on ", @"") stringByAppendingString:postTitle];
    postTitle = [author stringByAppendingString:[NSString stringWithFormat:@" %@: ", postTitle]];
    
    NSMutableAttributedString *attributedPostTitle = [[NSMutableAttributedString alloc] initWithString:postTitle attributes:[[self class] titleAttributesBold]];
    [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[contentProvider contentForDisplay] attributes:[[self class] titleAttributes]]];
    return attributedPostTitle;
}

@end


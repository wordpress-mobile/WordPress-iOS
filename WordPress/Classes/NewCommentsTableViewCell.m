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

+ (NSString *)titleTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    Comment *comment = (Comment *)contentProvider;
    
    // combine author and title
    NSString *author = [comment authorForDisplay];
    NSString *postTitle = [comment titleForDisplay];
    
    if (!(postTitle.length > 0)) {
        postTitle = NSLocalizedString(@"(No Title)", nil);
    }
    postTitle = [NSLocalizedString(@"on ", @"") stringByAppendingString:postTitle];
    
    return [author stringByAppendingString:[NSString stringWithFormat:@" %@", postTitle]];
}

+ (NSString *)detailTextForContentProvider:(id<WPContentViewProvider>)contentProvider {
    return [contentProvider contentForDisplay];
}



@end


//
//  NewNotificationsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewNotificationsTableViewCell.h"

@implementation NewNotificationsTableViewCell

+ (BOOL)showGravatarImage {
    return YES;
}

+ (BOOL)supportsUnreadStatus {
    return YES;
}

#pragma mark - Private Methods

+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    // combine author and title
    NSString *title = [contentProvider titleForDisplay];
    NSString *content = [contentProvider contentForDisplay];
    
    NSMutableAttributedString *attributedPostTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[[self class] titleAttributes]];
    if (content.length > 0) {
        [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@": "]];
        [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:content attributes:[[self class] titleAttributes]]];
    }
    return attributedPostTitle;
}

@end

//
//  NewPostTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewPostTableViewCell.h"
#import "Post.h"

@implementation NewPostTableViewCell


+ (BOOL)shortDateString {
    return NO;
}

+ (UIColor *)statusColorForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    Post *post = (Post *)contentProvider;
    
    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [UIColor lightGrayColor];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [WPStyleGuide jazzyOrange];
        } else {
            return [UIColor blackColor];
        }
    } else {
        if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
            return [WPStyleGuide newKidOnTheBlockBlue];
        } else if (post.remoteStatus == AbstractPostRemoteStatusFailed) {
            return [WPStyleGuide fireOrange];
        } else {
            return [WPStyleGuide jazzyOrange];
        }
    }
}

@end

//
//  NewNotificationsTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewNotificationsTableViewCell.h"
#import "NSString+HTML.h"

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
    NSString *content = [[contentProvider contentForDisplay] stringByNormalizingWhitespace];
    
    NSMutableAttributedString *attributedPostTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[[self class] titleAttributes]];
    
    // Bold text in quotes. This code should be rewritten when the API is more flexible
    // and includes out-of-band data
    NSScanner *scanner = [NSScanner scannerWithString:title];
    NSString *tmp;
    
    while ([scanner isAtEnd] == NO)
    {
        [scanner scanUpToString:@"\"" intoString:NULL];
        [scanner scanString:@"\"" intoString:NULL];
        [scanner scanUpToString:@"\"" intoString:&tmp];
        [scanner scanString:@"\"" intoString:NULL];
        
        if (tmp.length > 0) {
            NSRange itemRange = [title rangeOfString:tmp];
            if (itemRange.location != NSNotFound) {
                [attributedPostTitle addAttributes:[[self class] titleAttributesBold] range:itemRange];
            }
        }
    }
    
    // Bold text up until "liked", "commented", or "followed"
    NSArray *keywords = @[@"liked", @"commented", @"followed"];
    for (NSString *keyword in keywords) {
        NSRange keywordRange = [title rangeOfString:keyword];
        if (keywordRange.location != NSNotFound) {
            [attributedPostTitle addAttributes:[[self class] titleAttributesBold] range:NSMakeRange(0, keywordRange.location)];
            break;
        }
    }
    

    if (content.length > 0) {
        [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@": "]];
        [attributedPostTitle appendAttributedString:[[NSAttributedString alloc] initWithString:content attributes:[[self class] titleAttributes]]];
    }

    return attributedPostTitle;
}

@end

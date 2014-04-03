//
//  AbstractComment.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AbstractComment.h"
#import "NSString+XMLExtensions.h"
#import "NSString+HTML.h"
#import "NSString+Helpers.h"

@implementation AbstractComment

@dynamic author;
@dynamic author_email;
@dynamic author_ip;
@dynamic author_url;
@dynamic commentID;
@dynamic content;
@dynamic dateCreated;
@dynamic link;
@dynamic parentID;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic type;


#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay {
    return [self.postTitle stringByDecodingXMLCharacters];
}

- (NSString *)authorForDisplay {
    return [self.author length] > 0 ? [[self.author stringByDecodingXMLCharacters] trim] : [self.author_email trim];
}

- (NSString *)blogNameForDisplay {
    return nil;
}

- (NSString *)statusForDisplay {
    return self.status;
}

- (NSString *)contentForDisplay {
    // Unescape HTML characters and add <br /> tags
    NSString *commentContent = [[self.content stringByDecodingXMLCharacters] trim];
    // Don't add <br /> tags after an HTML tag, as DTCoreText will handle that spacing for us
    NSRegularExpression *removeNewlinesAfterHtmlTags = [NSRegularExpression regularExpressionWithPattern:@"(?<=\\>)\n\n" options:0 error:nil];
    commentContent = [removeNewlinesAfterHtmlTags stringByReplacingMatchesInString:commentContent options:0 range:NSMakeRange(0, [commentContent length]) withTemplate:@""];
    commentContent = [commentContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];
    
    return commentContent;
}

- (NSString *)contentPreviewForDisplay {
    return [[[self.content stringByDecodingXMLCharacters] stringByStrippingHTML] stringByNormalizingWhitespace];
}

- (NSURL *)avatarURLForDisplay {
    return nil;
}

- (NSString *)gravatarEmailForDisplay {
    return [self.author_email trim];
}

- (NSDate *)dateForDisplay {
    return self.dateCreated;
}


@end

//
//  AbstractComment.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AbstractComment.h"


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
    return nil;
}

- (NSString *)authorForDisplay {
    return [self.author length] > 0 ? self.author : self.author_email;
}

- (NSString *)blogNameForDisplay {
    return nil;
}

- (NSString *)statusForDisplay {
    return nil;
}

- (NSString *)contentForDisplay {
    return self.content;
}

- (NSString *)contentPreviewForDisplay {
    return self.content;
}

- (NSString *)avatarUrlForDisplay {
    return nil;
}

- (NSDate *)dateForDisplay {
    return self.dateCreated;
}


@end

//
//  Comment.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-20.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "PostComment.h"
#import "Post.h"


@implementation PostComment

@dynamic content;
@dynamic post;

- (NSString *)description {
    return [NSString stringWithFormat:@"Comment\n\tcontent: %@, postKey: %@", self.content, self.post.simperiumKey];
}

- (BOOL)isEqualToObject:(TestObject *)otherObj {
    PostComment *other = (PostComment *)otherObj;

    BOOL contentEqual = [self.content isEqualToString:other.content];
    // Break these out for ease of debugging
    NSString *thisKey = self.post.simperiumKey;
    NSString *otherKey = other.post.simperiumKey;
    BOOL postEqual = [thisKey isEqualToString: otherKey];
    
    BOOL isEqual = contentEqual && postEqual;
    
    if (!isEqual)
        NSLog(@"Argh, Comment not equal");
    
    return isEqual;
}

@end

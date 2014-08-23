//
//  Post.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-20.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "Post.h"
#import "PostComment.h"


@implementation Post

@dynamic title;
@dynamic comments;


- (NSString *)description {
    return [NSString stringWithFormat:@"Post\n\ttitle: %@, numComments: %luu", self.title,(unsigned long)[self.comments count]];
}

- (BOOL)isEqualToObject:(TestObject *)otherObj {
    Post *other = (Post *)otherObj;
    BOOL titleEqual = [self.title isEqualToString:other.title];
    
    // Break these out for ease of debugging
    int numComments = (int)[self.comments count];
    int otherNumComments = (int)[other.comments count];
    BOOL numCommentsEqual =  numComments = otherNumComments;
    
    BOOL isEqual = titleEqual && numCommentsEqual;
    
    if (!isEqual)
        NSLog(@"Argh, Post not equal");
    
    return isEqual;
}

@end

//
//  Post.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-20.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TestObject.h"

@class PostComment;

@interface Post : TestObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSSet *comments;
@end

@interface Post (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(PostComment *)value;
- (void)removeCommentsObject:(PostComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

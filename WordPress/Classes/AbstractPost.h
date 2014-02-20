//
//  AbstractPost.h
//  WordPress
//
//  Created by Jorge Bernal on 12/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"


@interface AbstractPost : BasePost

// Relationships
@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) NSMutableSet * media;
@property (weak, readonly) AbstractPost *original;
@property (weak, readonly) AbstractPost *revision;
@property (nonatomic, strong) NSMutableSet * comments;

// Revision management
- (AbstractPost *)createRevision;
- (void)deleteRevision;
- (void)applyRevision;
- (void)updateRevision;
- (BOOL)isRevision;
- (BOOL)isOriginal;
- (void)cloneFrom:(AbstractPost *)source;
- (BOOL)hasSiteSpecificChanges;

+ (AbstractPost *)newDraftForBlog:(Blog *)blog;
+ (NSString *const)remoteUniqueIdentifier;
+ (void)mergeNewPosts:(NSArray *)newObjects forBlog:(Blog *)blog;
- (void)updateFromDictionary:(NSDictionary *)postInfo;

@end

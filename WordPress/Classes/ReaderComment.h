//
//  ReaderComment.h
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AbstractComment.h"
#import "ReaderPost.h"

@interface ReaderComment : AbstractComment

@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) ReaderPost *post;

+ (NSArray *)fetchCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;

@end

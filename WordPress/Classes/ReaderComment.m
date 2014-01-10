//
//  ReaderComment.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderComment.h"
#import "NSString+XMLExtensions.h"

@interface ReaderComment()

- (void)updateFromDictionary:(NSDictionary *)dict;

@end


@implementation ReaderComment

@dynamic depth;
@dynamic authorAvatarURL;
@dynamic post;
@dynamic childComments;
@dynamic parentComment;
@synthesize attributedContent;

+ (NSArray *)fetchCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderComment" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(post = %@)", post];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}


+ (NSArray *)fetchChildCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderComment" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(post = %@) && (parentID != 0)", post];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}


+ (NSArray *)fetchParentCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderComment" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(post = %@) && (parentID = 0)", post];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}


+ (void)syncAndThreadComments:(NSArray *)comments forPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {
	[comments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self createOrUpdateWithDictionary:obj forPost:post withContext:context];
	}];
	
    NSError *error;
    if(![context save:&error]){
        DDLogError(@"Failed to sync ReaderComments: %@", error);
    }
	
	// Thread relationships
	NSArray *commentsArr = [self fetchChildCommentsForPost:post withContext:context];
	[commentsArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ReaderComment *comment = (ReaderComment *)obj;
		
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ReaderComment" inManagedObjectContext:context]];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(post = %@) && (commentID = %@)", post, comment.parentID];
		[request setPredicate:predicate];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		NSError *error = nil;
		NSArray *arr = [context executeFetchRequest:request error:&error];
		if ([arr count]) {
			comment.parentComment = [arr objectAtIndex:0];
		} else {
			[context deleteObject:comment]; // no parent found so we don't want to show this. 
		}
	}];
	
	if(![context save:&error]){
        DDLogError(@"Failed to set ReaderComment Relationships: %@", error);
    }
	
	// Update depths
	commentsArr = [self fetchParentCommentsForPost:post withContext:context];
	__block void(__unsafe_unretained ^updateDepth)(NSArray *, NSNumber *) = ^void (NSArray *comments, NSNumber *depth) {
		for (ReaderComment *comment in comments) {
			comment.depth = depth;
			if([comment.childComments count] > 0) {
				updateDepth([comment.childComments allObjects], [NSNumber numberWithInteger:([depth integerValue] + 1)]);
			}
		}
	};
	updateDepth(commentsArr, @0);
	
    if(![context save:&error]){
        DDLogError(@"Failed to set ReaderComment Depths: %@", error);
    }
}


+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderComment"];
	request.predicate = [NSPredicate predicateWithFormat:@"(commentID = %@) AND (post.endpoint = %@)", [dict objectForKey:@"ID"], post.endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if(error != nil){
        DDLogError(@"Error finding ReaderPost: %@", error);
        return;
    }

	ReaderComment *comment;
    if ([results count] > 0) {
		comment = (ReaderComment *)[results objectAtIndex:0];
		
    } else {
		comment = (ReaderComment *)[NSEntityDescription insertNewObjectForEntityForName:@"ReaderComment"
														   inManagedObjectContext:context];
		comment.commentID = [dict objectForKey:@"ID"];
		comment.post = post;
    }
    
    [comment updateFromDictionary:dict];

}


- (void)updateFromDictionary:(NSDictionary *)dict {
	
	NSDictionary *author = [dict objectForKey:@"author"];
	
	self.author = [[author stringForKey:@"name"] stringByDecodingXMLCharacters];
	self.author_email = [author stringForKey:@"email"];
	self.author_url = [author stringForKey:@"URL"];
	self.authorAvatarURL = [author stringForKey:@"avatar_URL"];
	
	self.content = [dict stringForKey:@"content"];
	self.dateCreated = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
	self.link = [dict stringForKey:@"URL"];
	
	id parent = [dict objectForKey:@"parent"];
	if ([parent isKindOfClass:[NSDictionary class]]) {
		parent = [parent numberForKey:@"ID"];
	} else {
		parent = [dict numberForKey:@"parent"];
	}
	self.parentID = (NSNumber *)parent;

    self.status = [dict objectForKey:@"status"];
    self.type = [dict objectForKey:@"type"];

}


#pragma mark - WPContentViewProvider protocol

- (NSURL *)avatarURLForDisplay {
    return [NSURL URLWithString:self.authorAvatarURL];
}

@end

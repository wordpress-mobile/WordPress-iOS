//
//  ReaderComment.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderComment.h"

@interface ReaderComment()

- (void)updateFromDictionary:(NSDictionary *)dict;

@end


@implementation ReaderComment

@dynamic authorAvatarURL;
@dynamic post;

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


+ (void)syncComments:(NSArray *)comments forPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context {
	[comments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self createOrUpdateWithDictionary:obj forPost:post withContext:context];
	}];
	
    NSError *error;
    if(![context save:&error]){
        NSLog(@"Failed to sync ReaderPosts: %@", error);
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
        NSLog(@"Error finding ReaderPost: %@", error);
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
	
	self.author = [author objectForKey:@"name"];
	self.author_email = [author objectForKey:@"email"];
	self.author_url = [author objectForKey:@"URL"];
	self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
	
	self.content = [dict objectForKey:@"content"];
	self.dateCreated = [dict objectForKey:@"date"];
	self.link = [dict objectForKey:@"URL"];
	
	NSNumber *parent = [dict objectForKey:@"parent"];
	if ([parent integerValue]) {
		self.parentID = parent;
	}

    self.status = [dict objectForKey:@"status"];
    self.type = [dict objectForKey:@"type"];

}


@end

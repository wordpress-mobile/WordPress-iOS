//
//  DraftManager.m
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import "DraftManager.h"

@implementation DraftManager

- (id)init {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (Post *)get:(NSString *)uniqueID {
	NSArray *items = nil;
	if(uniqueID != nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(isLocalDraft == YES) AND (uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	Post *post = nil;
	if((items != nil) && (items.count > 0)) {
		post = [items objectAtIndex:0];
		NSLog(@"draftManager post: %@", post);
	}
	else {
		post = (Post *)[NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
		[post setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
		[post setPostID:post.uniqueID];
	}
	return post;
}

- (BOOL)exists:(NSString *)uniqueID {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isLocalDraft == YES) AND (uniqueID like %@)", uniqueID];
	[request setPredicate:predicate];	
	
	NSError *error;
	NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
	[request release];
	
	if((items != nil) && (items.count > 0))
		return YES;
	else
		return NO;
}

- (void)save:(Post *)post {
	NSLog(@"saving draft: %@", post);
	if((post.uniqueID == nil) || ([self exists:post.uniqueID] == NO)) {
		[post setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
		[self insert:post];
	}
	else {
		[self update:post];
	}
}

- (void)insert:(Post *)post {
	[self dataSave];
}

- (void)update:(Post *)post {
	[self dataSave];
}

- (void)remove:(Post *)post {
	[appDelegate.managedObjectContext deleteObject:post];
	[appDelegate.managedObjectContext processPendingChanges];
}

- (void)dataSave {
    NSError *error;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

@end

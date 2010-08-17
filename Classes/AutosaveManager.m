//
//  AutosaveManager.m
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AutosaveManager.h"

@implementation AutosaveManager

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
								  @"(isAutosave == YES) AND (uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	Post *post = nil;
	if((items != nil) && (items.count > 0)) {
		post = [items objectAtIndex:0];
	}
	else {
		post = (Post *)[NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
		[post setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	return post;
}

- (BOOL)exists:(NSString *)uniqueID {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isAutosave == YES) AND (uniqueID like %@)", uniqueID];
	[request setPredicate:predicate];	
	
	NSError *error;
	NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
	[request release];
	
	if((items != nil) && (items.count > 0))
		return YES;
	else
		return NO;
}

- (NSMutableArray *)getForPostID:(NSString *)postID {
	NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isAutosave == YES) AND (postID like %@)", postID];
	[request setPredicate:predicate];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSError *error;
	NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
	[request release];
	
	int autosaveCount = 0;
	for(Post *autosave in items) {
		if(autosaveCount <= 7)
			[results addObject:autosave];
		else
			[self remove:autosave];
		autosaveCount++;
	}
	NSLog(@"total of %d autosaves for postID: %@", results.count, postID);
	
	return results;
}

- (NSArray *)getAll {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isAutosave == YES)"];
	[request setPredicate:predicate];	
	
	NSError *error;
	NSArray *items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
	[request release];
	
	return items;
}

- (int)totalAutosavesOnDevice {
	return [self getAll].count;
}

- (void)save:(Post *)post {
	[self dataSave];
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

- (BOOL)hasAutosaves:(NSString *)postID {
	if([self getForPostID:postID].count > 0)
		return YES;
	else
		return NO;
}

- (void)removeAllForPostID:(NSString *)postID {
	for(Post *post in [self getForPostID:postID]) {
		[self remove:post];
	}
}					   
					   
- (void)removeAll {
	for(Post *post in [self getAll]) {
		[appDelegate.managedObjectContext deleteObject:post];
	}
	[appDelegate.managedObjectContext processPendingChanges];
}

- (void)removeNewerThan:(NSDate *)date {
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];   
	NSFetchRequest *request = [[NSFetchRequest alloc] init];  
	[request setEntity:entity];   
	
	// Define how we will sort the records  
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];  
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];  
	[request setSortDescriptors:sortDescriptors];  
	[sortDescriptor release];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isAutosave == YES) AND (dateCreated < %@)", date];
	[request setPredicate:predicate];	
	
	NSError *error;  
	NSMutableArray *mutableFetchResults = [[appDelegate.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];   
	[request release];
	
	if (!mutableFetchResults) {  
		// Handle the error.  
	}
	
	for(NSManagedObject *obj in mutableFetchResults) {
		[appDelegate.managedObjectContext deleteObject:obj];
	}
	[appDelegate.managedObjectContext processPendingChanges];
	[mutableFetchResults release];
}

- (void)removeOlderThan:(NSDate *)date {
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];   
	NSFetchRequest *request = [[NSFetchRequest alloc] init];  
	[request setEntity:entity];   
	
	// Define how we will sort the records  
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];  
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];  
	[request setSortDescriptors:sortDescriptors];  
	[sortDescriptor release];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isAutosave == YES) AND (dateCreated > %@)", date];
	[request setPredicate:predicate];	
	
	NSError *error;  
	NSMutableArray *mutableFetchResults = [[appDelegate.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];   
	[request release];
	 
	if (!mutableFetchResults) {  
		// Handle the error.  
	}
	
	for(NSManagedObject *obj in mutableFetchResults) {
		[appDelegate.managedObjectContext deleteObject:obj];
	}
	[appDelegate.managedObjectContext processPendingChanges];
	[mutableFetchResults release];
}

- (void)dataSave {
    NSError *error;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

@end

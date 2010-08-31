//
//  MediaManager.m
//  WordPress
//
//  Created by Chris Boyd on 8/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "MediaManager.h"

@implementation MediaManager

- (id)init {
    if((self = [super init])) {
		appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (Media *)get:(NSString *)uniqueID {
	NSArray *items = nil;
	if(uniqueID != nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	Media *media = nil;
	if((items != nil) && (items.count > 0)) {
		media = [items objectAtIndex:0];
	}
	else {
		media = (Media *)[NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[media setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	return media;
}

- (NSMutableArray *)getForPostID:(NSString *)postID andBlogURL:(NSString *)blogURL andMediaType:(MediaType)mediaType {
	NSArray *items = nil;
	NSMutableArray *results = [[NSMutableArray alloc] init];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	if(postID != nil) {
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSString *mediaTypeString = @"image";
		if(mediaType == kVideo)
			mediaTypeString = @"video";
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(postID like %@) AND (blogURL like %@) AND (mediaType like %@)", postID, blogURL, mediaTypeString];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		
		for(Media *media in items) {
			[results addObject:media];
		}
		
		[request release];
	}
	
	return results;
}

- (BOOL)exists:(NSString *)uniqueID {
	NSArray *items = nil;
	if(uniqueID != nil) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueID like %@)", uniqueID];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	if((items != nil) && (items.count > 0))
		return YES;
	else
		return NO;
}

- (void)save:(Media *)media {
	if((media.uniqueID == nil) || ([self exists:media.uniqueID] == NO)) {
		[media setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
		[self insert:media];
	}
	else {
		[self update:media];
	}
}

- (void)insert:(Media *)media {
	[self dataSave];
}

- (void)update:(Media *)media {
	[self dataSave];
}

- (void)remove:(Media *)media {
	NSManagedObject *objectToDelete = media;
	[appDelegate.managedObjectContext deleteObject:objectToDelete];
	[self dataSave];
}

- (void)dataSave {
    NSError *error;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

@end

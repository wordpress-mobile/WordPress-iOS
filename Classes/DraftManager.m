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
								  @"(local == YES)"];
		[request setPredicate:predicate];
		
		NSError *error;
		items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
		[request release];
	}
	
	if((items == nil) || (items.count == 0)) {
		Post *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
		post.status = @"Local Draft";
        post.local = YES;
		return post;
	}
	
	return [items objectAtIndex:0];
}

- (NSMutableArray *)getType:(NSString *)postType forBlog:(NSString *)blogID {
	NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];   	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];  
    [request setEntity:entity];   
	
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateModified" ascending:NO];  
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];  
    [request setSortDescriptors:sortDescriptors];  
    [sortDescriptor release];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(local == YES) AND (blogID == %@)", blogID];
	[request setPredicate:predicate];
	
    NSError *error;  
    NSMutableArray *mutableFetchResults = [[appDelegate.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];   
	
    if (!mutableFetchResults) {  
        // Handle the error.  
        // This is a serious error and should advise the user to restart the application  
    }   
	
	for(Post *draft in mutableFetchResults) {
		[results addObject:draft];
	}
	
    [mutableFetchResults release];
    [request release];
	
	return results;
}

- (BOOL)exists:(NSString *)uniqueID {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:appDelegate.managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(local == YES)"];
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
	if(post.postID == nil) {
		[self insert:post];
	}
	else {
		[self update:post];
	}
}

- (void)insert:(Post *)post {
	[self dataSave];
	[appDelegate.managedObjectContext processPendingChanges];
}

- (void)update:(Post *)post {
	[self dataSave];
	[appDelegate.managedObjectContext processPendingChanges];
}

- (void)remove:(Post *)post {
	NSManagedObject *objectToDelete = post;
	[appDelegate.managedObjectContext deleteObject:objectToDelete];
	[appDelegate.managedObjectContext processPendingChanges];
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

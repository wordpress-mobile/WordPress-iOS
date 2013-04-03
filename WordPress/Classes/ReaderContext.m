//
//  ReaderContext.m
//  WordPress
//
//  Created by Eric J on 3/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderContext.h"
#import "WordPressAppDelegate.h"

@interface ReaderContext ()  {
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@end

@implementation ReaderContext

#pragma mark -
#pragma mark Singleton

+ (ReaderContext *)sharedReaderContext {
	static ReaderContext *instance = nil;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		instance = [[ReaderContext alloc] init];
	});
	return instance;
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the reader.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the reader.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
	
    return managedObjectContext_;
}


/**
 Returns the persistent store coordinator for the reader.
 Reader models use the Reader configuration so our persistent store coordinator will focus on it alone.
 If the coordinator doesn't already exist, it is created.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationDocumentsDirectory] stringByAppendingPathComponent: @"WordPress.sqlite"]];
	
	NSString *config = nil;
	NSManagedObjectModel *mom = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectModel];
	
	NSUInteger idx = [[mom configurations] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		if([@"Reader" isEqualToString:(NSString *)obj]) {
			stop = YES;
			return YES;
		}
		return NO;
	}];
	if (idx != NSNotFound){
		config = [[mom configurations] objectAtIndex:idx];
	}
	
	
	if([[mom configurations] indexOfObjectIdenticalTo:@"Reader"] != NSNotFound) {
		config = [[mom configurations] objectAtIndex:[[mom configurations] indexOfObjectIdenticalTo:@"Reader"]];
	}
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];
	
	NSError *error = nil;
	
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:config
															 URL:storeURL
														 options:options
														   error:&error]) {
		// TODO do nothing?
		NSLog(@"Failed to create persistentStoreCoordinator");
	}
    
    return persistentStoreCoordinator_;
}


@end

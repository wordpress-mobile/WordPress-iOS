//
//  MockSimperium.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "MockSimperium.h"
#import "TestParams.h"



#pragma mark ====================================================================================
#pragma mark Simperium: Exposing Private Methods
#pragma mark ====================================================================================

@interface Simperium ()
@property (nonatomic, strong) id<SPNetworkInterface> network;
@end


#pragma mark ====================================================================================
#pragma mark MockSimperium
#pragma mark ====================================================================================

@implementation MockSimperium

+ (MockSimperium*)mockSimperium {
    // Use an in-memory store for testing
	NSError *error = nil;
	NSManagedObjectContext* context				= [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	NSManagedObjectModel* model					= [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
	NSPersistentStoreCoordinator* coordinator	= [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
	
	// This instance won't have backend interaction. Let's just add a dummy user!.
	MockSimperium* s		= [[MockSimperium alloc] initWithModel:model context:context coordinator:coordinator];
	[s authenticateWithAppID:APP_ID token:@"Dummy"];
	
	return s;
}

- (MockWebSocketInterface*)mockWebSocketInterface {
	return self.network;
}

@end

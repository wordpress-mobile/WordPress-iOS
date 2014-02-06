//
//  SPPersistentMutableDictionaryTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 9/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPPersistentMutableDictionary.h"
#import "NSString+Simperium.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSUInteger const SPMetadataIterations = 100;


#pragma mark ====================================================================================
#pragma mark SPPersistentMutableDictionaryTests
#pragma mark ====================================================================================

@interface SPPersistentMutableDictionaryTests : XCTestCase

@end

@implementation SPPersistentMutableDictionaryTests

- (void)testInserts {
	NSString *storageLabel = [NSString sp_makeUUID];
	SPPersistentMutableDictionary *storage = [SPPersistentMutableDictionary loadDictionaryWithLabel:storageLabel];
	NSMutableDictionary *integrity = [NSMutableDictionary dictionary];
		
	// Test SetObject
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		NSDictionary *random = [self randomContentObject];
		NSString* key = [NSString stringWithFormat:@"%ld", (long)i];
		[storage setObject:random forKey:key];
		[integrity setObject:random forKey:key];
	}

	[storage save];
	
	XCTAssertTrue( (storage.count == SPMetadataIterations), @"setObject Failed");
	
	// Test Hitting NSCache
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		NSString* key = [NSString stringWithFormat:@"%ld", (long)i];
		NSDictionary *retrieved = [storage objectForKey:key];
		NSDictionary *verify = [integrity objectForKey:key];

		XCTAssertEqualObjects(retrieved, verify, @"Error retrieving object from NSCache");
		XCTAssertTrue([storage containsObjectForKey:key], @"Error in containsObjectForKey");
	}

	// Test Hitting CoreData: Re-instantiate, so NSCache is empty
	storage = [SPPersistentMutableDictionary loadDictionaryWithLabel:storageLabel];
	
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		NSString* key = [NSString stringWithFormat:@"%ld", (long)i];
		NSDictionary *retrieved = [storage objectForKey:key];
		NSDictionary *verify = [integrity objectForKey:key];
		
		XCTAssertTrue([retrieved isEqual:verify], @"Error retrieving object From CoreData");
		XCTAssertTrue([storage containsObjectForKey:key], @"Error in containsObjectForKey");
	}
	
	// Cleanup
	[storage removeAllObjects];
	[storage save];
	[integrity removeAllObjects];
	XCTAssertTrue( (storage.count == 0), @"RemoveAllObjects Failed");
}

- (void)testRemoval {
	NSString *storageLabel = [NSString sp_makeUUID];
	SPPersistentMutableDictionary *storage = [SPPersistentMutableDictionary loadDictionaryWithLabel:storageLabel];
		
	// Insert N objects
	NSMutableSet *allKeys = [NSMutableSet set];
	
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		NSDictionary *random = [self randomContentObject];
		NSString* key = [NSString stringWithFormat:@"%ld", (long)i];
		[storage setObject:random forKey:key];
		[allKeys addObject:key];
	}
	
	[storage save];
	
	// Remove all of them
	for (NSString *key in allKeys) {
		id object = [storage objectForKey:key];
		XCTAssertNotNil(object, @"Error retrieving object");
		
		[storage removeObjectForKey:key];
		object = [storage objectForKey:key];
		XCTAssertNil(object, @"Error removing object");
		XCTAssertFalse([storage containsObjectForKey:key], @"Error in containsObjectForKey");
	}
	
	[storage save];
	
	// Make sure next time they'll ""stay removed""
	storage = [SPPersistentMutableDictionary loadDictionaryWithLabel:storageLabel];
	
	for (NSString *key in allKeys) {
		id object = [storage objectForKey:key];
		XCTAssertNil(object, @"Zombie Objects Found!");
		XCTAssertFalse([storage containsObjectForKey:key], @"Error in containsObjectForKey");
	}
	
	// Cleanup
	[allKeys removeAllObjects];
}

- (void)testNamespaces {
	// Fresh Start
	NSString *firstLabel = [NSString sp_makeUUID];
	NSString *secondLabel = [NSString sp_makeUUID];
	SPPersistentMutableDictionary *firstStorage = [SPPersistentMutableDictionary loadDictionaryWithLabel:firstLabel];
	SPPersistentMutableDictionary *secondStorage = [SPPersistentMutableDictionary loadDictionaryWithLabel:secondLabel];
		
	// Insert in the first storage
	NSMutableSet *allKeys = [NSMutableSet set];
	
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		NSDictionary *random = [self randomContentObject];
		NSString* key = [NSString stringWithFormat:@"%ld", (long)i];
		[firstStorage setObject:random forKey:key];
		[allKeys addObject:key];
	}
	
	[firstStorage save];
	
	// Verify that the second storage doesn't return anything for those keys
	for (NSString *key in allKeys) {
		id object = [secondStorage objectForKey:key];
		XCTAssertNil(object, @"Namespace Integrity Breach");
	}
	
	// Cleanup
	[firstStorage removeAllObjects];
	[firstStorage save];
	
	[secondStorage removeAllObjects];
	[secondStorage save];
}


#pragma mark ====================================================================================
#pragma mark Helpers
#pragma mark ====================================================================================

- (NSDictionary*)randomContentObject {
	NSMutableDictionary *random = [NSMutableDictionary dictionary];
	
	for (NSInteger i = 0; ++i <= SPMetadataIterations; ) {
		[random setObject:[NSString sp_makeUUID] forKey:[NSString sp_makeUUID]];
	}
	
	return random;
}

@end

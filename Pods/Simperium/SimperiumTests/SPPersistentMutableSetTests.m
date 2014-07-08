//
//  SPPersistentMutableSetTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/14/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPPersistentMutableSet.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSUInteger const SPInsertCount = 10000;
static NSUInteger const SPDeleteCount = 500;


#pragma mark ====================================================================================
#pragma mark SPPersistentMutableSetTests
#pragma mark ====================================================================================

@interface SPPersistentMutableSetTests : XCTestCase

@end

@implementation SPPersistentMutableSetTests

- (void)testCRUD {
	// Test: Create
	SPPersistentMutableSet *first = [SPPersistentMutableSet loadSetWithLabel:@"first"];
	NSInteger total = 0;
	for (NSInteger i = 0; ++i <= SPInsertCount; ) {
		[first addObject:@(i)];
		total += i;
	}
	[first saveAndWait:YES];
	XCTAssertTrue(first.count == SPInsertCount, @"Insertion Issue");
	
	// Test: Retrieve
	first = [SPPersistentMutableSet loadSetWithLabel:@"first"];
	NSInteger control = 0;
	for (NSNumber *number in first.allObjects) {
		control += number.intValue;
	}
	
	XCTAssertTrue(control == total, @"Retrieve Issue");
	
	// Test: Delete
	NSMutableSet *deletions = [NSMutableSet set];
	NSInteger deletedSum = 0;
	for (NSNumber *num in first.allObjects) {
		[deletions addObject:num];
		deletedSum += num.intValue;
		if (deletions.count == SPDeleteCount) {
			break;
		}
	}
	[first minusSet:deletions];
	XCTAssertTrue(first.count == (SPInsertCount - SPDeleteCount), @"Deletion Issue");
	
	NSInteger newTotal = 0;
	for (NSNumber *num in first.allObjects) {
		newTotal += num.intValue;
	}
	
	XCTAssertTrue(newTotal == (total - deletedSum) , @"");
	
	// Test: Nuke
	[first removeAllObjects];
	[first saveAndWait:YES];
	
	first = [SPPersistentMutableSet loadSetWithLabel:@"first"];
	XCTAssert(first.count == 0, @"Removal Issue");
}

- (void)testNamespaces {
	// Insert: 'first'
	SPPersistentMutableSet *first = [SPPersistentMutableSet loadSetWithLabel:@"first"];
	for (NSInteger i = 0; ++i <= SPInsertCount; ) {
		[first addObject:@(i)];
	}
	[first saveAndWait:YES];
	XCTAssert(first.count == SPInsertCount, @"Insert Issue");
	
	// Verify: 'second'
	SPPersistentMutableSet *second = [SPPersistentMutableSet loadSetWithLabel:@"second"];
	XCTAssert(second.count == 0, @"Namespaces Issue");
}

- (void)testFastEnumeration {
    
    NSMutableSet *control = [NSMutableSet set];
	SPPersistentMutableSet *first = [SPPersistentMutableSet loadSetWithLabel:@"first"];
	for (NSInteger i = 0; ++i <= SPInsertCount; ) {
		[first addObject:@(i)];
        [control addObject:@(i)];
	}
    
    for (NSNumber *number in first) {
        XCTAssert([control containsObject:number], @"Enumeration Issue");
        [control removeObject:number];
    }
    
    XCTAssert(control.count == 0, @"Enumeration missed an object");
}

@end

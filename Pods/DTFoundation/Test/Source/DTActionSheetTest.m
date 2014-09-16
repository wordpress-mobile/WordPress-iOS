//
//  DTActionSheetTest.m
//  DTFoundation
//
//  Created by Rene Pirringer on 22.07.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DTActionSheet.h"


@interface DTActionSheet(Private) <UIActionSheetDelegate>
@end


@implementation DTActionSheet(Private)
@end


@interface DTActionSheetTest : XCTestCase
@end


@implementation DTActionSheetTest

- (void)testInitMethods {
	__block BOOL blockExecuted = NO;
	DTActionSheet *actionSheet = [[DTActionSheet alloc] init];
	[actionSheet addButtonWithTitle:@"Ok" block:^{
		blockExecuted = YES;
	}];

	[actionSheet actionSheet:actionSheet clickedButtonAtIndex:actionSheet.numberOfButtons - 1];
	
	XCTAssertTrue(blockExecuted, @"The ok button block should be executed");

    blockExecuted = NO;
    actionSheet = [[DTActionSheet alloc] initWithTitle:@"Foo"];
    [actionSheet addButtonWithTitle:@"Ok" block:^{
        blockExecuted = YES;
    }];
    
    [actionSheet actionSheet:actionSheet clickedButtonAtIndex:actionSheet.numberOfButtons - 1];
    
    XCTAssertTrue(blockExecuted, @"The ok button block should be executed");

    blockExecuted = NO;
    actionSheet = [[DTActionSheet alloc] initWithTitle:@"Foo" delegate:nil cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"a", @"b", nil];
    [actionSheet addButtonWithTitle:@"Ok" block:^{
        blockExecuted = YES;
    }];
    
    [actionSheet actionSheet:actionSheet clickedButtonAtIndex:actionSheet.numberOfButtons - 1];
    
    XCTAssertTrue(blockExecuted, @"The ok button block should be executed");
}

- (void)testInitMethod_delegate {
	
	__block BOOL blockExecuted = NO;
	DTActionSheet *actionSheet = [[DTActionSheet alloc] initWithTitle:@"Test title"];
	[actionSheet addCancelButtonWithTitle:@"Cancel" block:nil];
	[actionSheet addButtonWithTitle:@"Ok" block:^{
		blockExecuted = YES;
	}];
	
	[actionSheet.delegate actionSheet:actionSheet clickedButtonAtIndex:actionSheet.numberOfButtons -1 ];
	XCTAssertTrue(blockExecuted, @"The ok button block should be executed");
}


@end

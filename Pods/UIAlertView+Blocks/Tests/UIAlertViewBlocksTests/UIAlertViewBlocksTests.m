//
//  UIAlertViewBlocksTests.m
//  UIAlertViewBlocksTests
//
//  Created by Ryan Maxwell on 7/09/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIAlertView+Blocks.h"

@interface UIAlertViewBlocksTests : XCTestCase <UIAlertViewDelegate>
@property (strong, nonatomic) UIAlertView *alertView;
@end

@implementation UIAlertViewBlocksTests

- (void)setUp {
    [super setUp];
    
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Test"
                                                message:@"Test"
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
}

- (void)tearDown {
    self.alertView = nil;
    
    [super tearDown];
}

- (void)testSettingTapBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localTapBlock)(UIAlertView *alertView, NSInteger buttonIndex) = ^void(UIAlertView *alertView, NSInteger buttonIndex){
        NSLog(@"Tapped Alert");
    };
    
    self.alertView.tapBlock = localTapBlock;
    
    XCTAssertEqualObjects(self.alertView.tapBlock, localTapBlock, @"The Alert View tap block should equal the local tap block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

- (void)testSettingWillDismissBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localWillDismissBlock)(UIAlertView *alertView, NSInteger buttonIndex) = ^void(UIAlertView *alertView, NSInteger buttonIndex){
        NSLog(@"Will Dismiss Alert");
    };
    
    self.alertView.willDismissBlock = localWillDismissBlock;
    
    XCTAssertEqualObjects(self.alertView.willDismissBlock, localWillDismissBlock, @"The Alert View will dismiss block should equal the local will dismiss block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

- (void)testSettingDidDismissBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localDidDismissBlock)(UIAlertView *alertView, NSInteger buttonIndex) = ^void(UIAlertView *alertView, NSInteger buttonIndex){
        NSLog(@"Did Dismiss Alert");
    };
    
    self.alertView.didDismissBlock = localDidDismissBlock;
    
    XCTAssertEqualObjects(self.alertView.didDismissBlock, localDidDismissBlock, @"The Alert View did dismiss block should equal the local did dismiss block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

- (void)testSettingCancelBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localCancelBlock)(UIAlertView *alertView) = ^void(UIAlertView *alertView){
        NSLog(@"Cancelled Alert");
    };
    
    self.alertView.cancelBlock = localCancelBlock;
    
    XCTAssertEqualObjects(self.alertView.cancelBlock, localCancelBlock, @"The Alert View cancel block should equal the local cancel block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

- (void)testSettingWillPresentBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localWillPresentBlock)(UIAlertView *alertView) = ^void(UIAlertView *alertView){
        NSLog(@"Will Present Alert");
    };
    
    self.alertView.willPresentBlock = localWillPresentBlock;
    
    XCTAssertEqualObjects(self.alertView.willPresentBlock, localWillPresentBlock, @"The Alert View will present block should equal the local will present block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

- (void)testSettingDidPresentBlock {
    XCTAssertEqualObjects(self.alertView.delegate, self, @"The Alert View Delegate should be self");
    
    void (^localDidPresentBlock)(UIAlertView *alertView) = ^void(UIAlertView *alertView){
        NSLog(@"Did Present Alert");
    };
    
    self.alertView.didPresentBlock = localDidPresentBlock;
    
    XCTAssertEqualObjects(self.alertView.didPresentBlock, localDidPresentBlock, @"The Alert View did present block should equal the local did present block");
    XCTAssertEqualObjects(self.alertView.delegate, self.alertView, @"The Alert View Delegate should be the alert");
}

@end

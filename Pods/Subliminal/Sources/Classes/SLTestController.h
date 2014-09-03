//
//  SLTestController.h
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>


/**
 `SLTestController` coordinates test execution. Its singleton instance
 is the primary interface between the application and the tests.
 */
@interface SLTestController : NSObject

#pragma mark - Configuring the Default Timeout
/// -------------------------------------------
/// @name Configuring the Default Timeout
/// -------------------------------------------

/**
 Subliminal's timeout.
 
 Various classes within Subliminal use this timeout to control operations that 
 involve waiting. In particular, this timeout is used to wait for interface elements
 to become valid and/or tappable, as required by the tests. 
 See `+[SLUIAElement defaultTimeout]`.
 
 The default value is 5 seconds.
 */
@property (nonatomic) NSTimeInterval defaultTimeout;

#pragma mark - Getting the Shared Test Controller
/// -------------------------------------------
/// @name Getting the Shared Test Controller
/// -------------------------------------------

/**
 Returns the test controller.
 
 @return The shared `SLTestController` instance.
 */
+ (instancetype)sharedTestController;

#pragma mark - Running Tests
/// -------------------------------------------
/// @name Running Tests
/// -------------------------------------------

/**
 Run the specified tests by invoking `runTests:usingSeed:withCompletionBlock:` 
 with `SLTestControllerRandomSeed` and the specified completion block.

 @param tests The set of tests to run.
 @param completionBlock An optional block to execute once testing has finished.
 */
- (void)runTests:(NSSet *)tests withCompletionBlock:(void (^)())completionBlock;

/**
 Runs the specified tests.

 Tests are run on a background queue. Tests run in ascending order of [group](+[SLTest runGroup]),
 and then within each group, in an order randomized using the specified seed.
 Clients should generally pass `SLTestControllerRandomSeed` to let the test controller choose a seed.
 If any tests fail, the test controller will log the seed that was used,
 so that the run order may be reproduced by invoking this method with that seed.

 Tests must [support the current platform](+[SLTest supportsCurrentPlatform]) in order to be run.
 If any tests [are focused](+[SLTest isFocused]), only those tests will be run.
 
 When using a given seed, tests execute in the same relative order regardless of focus.
 That is, if a set of tests _| A, B, C, D |_ (all unfocused) 
 are run in order _[ B, A, C, D ]_ when using a certain seed,
 when tests _B_ and _C_ are focused, they will be run in order _[ B, C ]_.

 When all tests have finished, the completion block (if provided)
 will be executed on the main queue. The test controller will then signal 
 UIAutomation to finish executing commands.
 
 @param tests The set of tests to run.
 @param seed  The seed to use to randomize the tests.
 If `SLTestControllerRandomSeed` is passed, the test controller will choose a seed.
 @param completionBlock An optional block to execute once testing has finished.
 */
- (void)runTests:(NSSet *)tests usingSeed:(unsigned int)seed withCompletionBlock:(void (^)())completionBlock;

@end


/**
 The methods in the `SLTestController (DebugSettings)` category may be useful 
 in debugging tests.
 */
@interface SLTestController (DebugSettings)

#pragma mark - Debugging Tests
/// -------------------------------------------
/// @name Debugging Tests
/// -------------------------------------------

/**
 Determines whether the controller should wait, after `-runTests:withCompletionBlock:` 
 is invoked, to start testing.
 
 If this is YES, the test controller will show an alert after 
 `runTests:withCompletionBlock:` is invoked and will not begin testing until 
 the developer has dismissed that alert.
 
 This allows the developer time to attach the debugger to the tests. That is done 
 by launching the tests, then clicking the following menu items, in Xcode:
 
    Product -> Attach to Process -> <name of testing target, at top>
 
 This setting will only take effect if the target is built in the "Debug"
 configuration (with the `DEBUG` preprocessor macro set). This is to prevent the 
 alert from showing when built (in "Release") for an unattended, continuous 
 integration run; and to ensure that debug information will be available to the 
 debugger (whereas the Release configuration may optimize that information away).
 
 To build the tests in Debug, click the the "Scheme" dropdown in the upper
 left-hand corner, then the following menu items:
    
    <Manage Scheme> -> (double-click) <name of your "Integration Tests" scheme> -> 
    "Profile" (in the left side-bar)
 
 and change the "Build Configuration" to "Debug". 
 */
@property (nonatomic) BOOL shouldWaitToStartTesting;

@end


#pragma mark - Constants

/// A value that may be passed to `-runTests:usingSeed:withCompletionBlock:`
/// to indicate that the test controller should choose a seed.
extern const unsigned int SLTestControllerRandomSeed;

//
//  AsyncTestHelper.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AsyncTestHelper.h"

dispatch_semaphore_t ATHSemaphore;
const NSTimeInterval AsyncTestCaseDefaultTimeout = 10;
//
//  NSObject_SafeExpectations.h
//  NSObject-SafeExpectationsTests
//
//  Created by Jorge Bernal on 2/6/13.
//
//

#import <Foundation/Foundation.h>
#import "NSDictionary+SafeExpectations.h"

#if !defined(NSSE_USE_ASSERTIONS)
#define NSSEAssert(cond,desc,...) NSAssert(cond,desc,##__VA_ARGS__)
#else
#define NSSEAssert(cond,desc,...) do {} while (0)
#endif // NSSE_USE_ASSERTIONS


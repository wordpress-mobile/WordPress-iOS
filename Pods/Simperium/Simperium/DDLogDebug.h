//
//  DDLogDebug.h
//  Simperium
//
//  Created by Michael Johnston on 11-09-23.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

// The first 4 bits are being used by the standard levels (0 - 3) 
// All other bits are fair game for us to use.

#define LOG_FLAG_DEBUG    (1 << 4)  // 0...0010000
//#define LOG_FLAG_SLEEP_TIMER   (1 << 5)  // 0...0100000

#define LOG_DEBUG  (ddLogLevel & LOG_FLAG_DEBUG)
//#define LOG_SLEEP_TIMER (ddLogLevel & LOG_FLAG_SLEEP_TIMER)

#define DDLogDebug(frmt, ...)   ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_DEBUG, 0, frmt, ##__VA_ARGS__)

#define DDLogOnError(error) 	if(error != nil && [error isKindOfClass:[NSError class]]) { DDLogError(@"%@ error while executing '%@': %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error); }

//#define DDLogSleepTimer(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_SLEEP_TIMER, frmt, ##__VA_ARGS__)

// Now we decide which flags we want to enable in our application
//#define LOG_FLAG_TIMERS (LOG_FLAG_FOOD_TIMER | LOG_FLAG_SLEEP_TIMER))

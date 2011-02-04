//
//  HTTPHelper.h
//
//  Created by Tyler Neylon on 6/20/09.
//  Copyright 2009 Bynomial. All rights reserved.
//
//  Helper class for working with HTTP connections.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "HTTPHelperDelegate.h"

typedef enum {
	HTTPStateNoConnection,
	HTTPStateAwaitingFullResponse } HTTPState;

@interface HTTPHelper : NSObject {
	NSTimeInterval timeOut;
	HTTPState state;
	NSMutableData *dataSoFar;
	NSURLConnection *connection;
	id<HTTPHelperDelegate> delegate;
}

@property NSTimeInterval timeOut;

+ (HTTPHelper *)sharedInstance;
- (NSError *)synchronousGetURLAsString:(NSString *)URLAsString replyData: (NSString**)dataStr;
- (NSError *)synchronousPostUrlAsString:(NSString *)UrlAsString withRequest:(NSString *)requestString replyData:(NSString **)reply;
- (void)asynchronousGetURLAsString:(NSString *) URLAsString delegate: (id<HTTPHelperDelegate>) delegate_;

@end
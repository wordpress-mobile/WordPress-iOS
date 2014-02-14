//
//  SPAuthenticator.m
//  Simperium
//
//  Created by Michael Johnston on 12-02-27.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "Simperium+Internals.h"
#import "SPEnvironment.h"
#import "SPUser.h"
#import "SPAuthenticator.h"
#import "SPBinaryManager.h"
#import "JSONKit+Simperium.h"
#import "STKeychain.h"
#import "SPReachability.h"
#import "SPHttpRequest.h"
#import "SPHttpRequestQueue.h"
#import "SPLogger.h"

#define USERNAME_KEY @"SPUsername"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h> // for UIDevice
#else
#import <AppKit/NSApplication.h>
#endif



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel = SPLogLevelsInfo;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPAuthenticator()
@property (nonatomic, weak) id<SPAuthenticatorDelegate>	delegate;
@property (nonatomic, weak) Simperium					*simperium;
@property (nonatomic, copy) SucceededBlockType			succeededBlock;
@property (nonatomic, copy) FailedBlockType				failedBlock;
@end


#pragma mark ====================================================================================
#pragma mark SPAuthenticator
#pragma mark ====================================================================================

@implementation SPAuthenticator

- (id)initWithDelegate:(id<SPAuthenticatorDelegate>)authDelegate simperium:(Simperium *)s {
    if ((self = [super init])) {
        self.delegate	= authDelegate;
        self.simperium	= s;
    }
    return self;
}

// Open a UI to handle authentication if necessary
- (BOOL)authenticateIfNecessary {
    // Look up a stored token (if it exists) and try authenticating
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:USERNAME_KEY];
    NSString *token = nil;
	
    if (username) {
		NSError *error = nil;
        token = [STKeychain getPasswordForUsername:username andServiceName:self.simperium.appID error:&error];
		
		if (error) {
			SPLogError(@"Simperium couldn't retrieve token from keychain. Error: %@", error);
		}
    }
	
    if (!username || username.length == 0 || !token || token.length == 0) {
        SPLogInfo(@"Simperium didn't find an existing auth token (username %@; token %@; appID: %@)", username, token, self.simperium.appID);
        if ([self.delegate respondsToSelector:@selector(authenticationDidFail)]) {
            [self.delegate authenticationDidFail];
        }
			
        return YES;
    }
	
	SPLogInfo(@"Simperium found an existing auth token for %@", username);
	// Assume the token is valid and return success
	// TODO: ensure if it isn't valid, a reauth process will get triggered

	// Set the Simperium user
	self.simperium.user = [[SPUser alloc] initWithEmail:username token:token];

	if ([self.delegate respondsToSelector:@selector(authenticationDidSucceedForUsername:token:)]) {
		[self.delegate authenticationDidSucceedForUsername:username token:token];
	}
	
    return NO;
}

// Perform the actual authentication calls to Simperium
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(SucceededBlockType)successBlock failure:(FailedBlockType)failureBlock
{    
    NSURL *tokenURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/authorize/", SPAuthURL, self.simperium.appID]];
    SPLogInfo(@"Simperium authenticating: %@", [NSString stringWithFormat:@"%@%@/authorize/", SPAuthURL, self.simperium.appID]);
    SPLogVerbose(@"Simperium username is %@", username);
	
	SPHttpRequest *request = [SPHttpRequest requestWithURL:tokenURL];
	request.headers = @{
		@"X-Simperium-API-Key"	: self.simperium.APIKey,
		@"Content-Type"			: @"application/json"
	};
	
    NSDictionary *authDict = @{
		@"username" : username,
		@"password" : password
	};

	request.method = SPHttpRequestMethodsPost;
	request.postData = [[authDict sp_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
	request.delegate = self;
	request.selectorSuccess	= @selector(authDidSucceed:);
	request.selectorFailed = @selector(authDidFail:);
	request.timeout = 8;
    
    // Blocks are used here for UI tasks on iOS/OSX
    self.succeededBlock = successBlock;
    self.failedBlock = failureBlock;
    
    // Selectors are for auth-related handling
	[[SPHttpRequestQueue sharedInstance] enqueueHttpRequest:request];
}

- (void)delayedAuthenticationDidFinish {
    if (self.succeededBlock) {
        self.succeededBlock();
		
		// Cleanup!
		self.failedBlock = nil;
		self.succeededBlock = nil;
	}
    
    SPLogInfo(@"Simperium authentication success!");

    if ([self.delegate respondsToSelector:@selector(authenticationDidSucceedForUsername:token:)]) {
        [self.delegate authenticationDidSucceedForUsername:self.simperium.user.email token:self.simperium.user.authToken];
	}
}

- (void)authDidSucceed:(SPHttpRequest *)request {
    NSString *tokenResponse = request.responseString;
    if (request.responseCode != 200) {
        [self authDidFail:request];
        return;
    }
    
    NSDictionary *userDict	= [tokenResponse sp_objectFromJSONString];
    NSString *username		= userDict[@"username"];
    NSString *token			= userDict[@"access_token"];
    
    // Set the user's details
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:USERNAME_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
	NSError *error = nil;
    BOOL success = [STKeychain storeUsername:username andPassword:token forServiceName:self.simperium.appID updateExisting:YES error:&error];
    
	if (success == NO) {
		SPLogError(@"Simperium couldn't store token in the keychain. Error: %@", error);
	}
	
    // Set the Simperium user
    self.simperium.user = [[SPUser alloc] initWithEmail:username token:token];
    
    [self performSelector:@selector(delayedAuthenticationDidFinish) withObject:nil afterDelay:0.1];
}

- (void)authDidFail:(SPHttpRequest *)request {
    if (self.failedBlock) {
        self.failedBlock(request.responseCode, request.responseString);
		
		// Cleanup!
		self.failedBlock = nil;
		self.succeededBlock = nil;
	}
    
    SPLogError(@"Simperium authentication error (%d): %@", request.responseCode, request.responseError);
    
    if ([self.delegate respondsToSelector:@selector(authenticationDidFail)]) {
        [self.delegate authenticationDidFail];
	}
}

- (void)createWithUsername:(NSString *)username password:(NSString *)password success:(SucceededBlockType)successBlock failure:(FailedBlockType)failureBlock {
    NSURL *tokenURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/create/", SPAuthURL, self.simperium.appID]];
    
    SPHttpRequest *request = [SPHttpRequest requestWithURL:tokenURL];
    NSMutableDictionary *authData = [@{
		@"username" : username,
		@"password" : password,
	} mutableCopy];
    
    // Backend authentication may need extra data
    if (self.providerString.length > 0) {
        [authData setObject:self.providerString forKey:@"provider"];
	}
    
	request.method = SPHttpRequestMethodsPost;
	request.postData = [[authData sp_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
	request.headers = @{
		@"Content-Type"			: @"application/json",
		@"X-Simperium-API-Key"	: self.simperium.APIKey
	};
    
    // Blocks are used here for UI tasks on iOS/OSX
    self.succeededBlock = successBlock;
    self.failedBlock = failureBlock;
    
    // Selectors are for auth-related handling
    request.delegate = self;
	request.selectorSuccess = @selector(authDidSucceed:);
	request.selectorFailed = @selector(authDidFail:);

	[[SPHttpRequestQueue sharedInstance] enqueueHttpRequest:request];
}

- (void)reset {
	SPLogVerbose(@"Simperium Authenticator resetting credentials");
	
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:USERNAME_KEY];
    if (!username || username.length == 0) {
        username = self.simperium.user.email;
	}
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USERNAME_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
    if (username && username.length > 0) {
        [STKeychain deleteItemForUsername:username andServiceName:self.simperium.appID error:nil];
	}
}

- (void)cancel {
    SPLogVerbose(@"Simperium authentication cancelled");
    
    if ([self.delegate respondsToSelector:@selector(authenticationDidCancel)]) {
        [self.delegate authenticationDidCancel];
	}
}

- (BOOL)connected {
	return (self.simperium.reachability.currentReachabilityStatus != NotReachable);
}

@end

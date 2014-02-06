//
//  SPAuthenticator.h
//  Simperium
//
//  Created by Michael Johnston on 12-02-27.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^SucceededBlockType)(void);
typedef void(^FailedBlockType)(int responseCode, NSString *responseString);

@class Simperium;

@protocol SPAuthenticatorDelegate <NSObject>
@optional
- (void)authenticationDidSucceedForUsername:(NSString *)username token:(NSString *)token;
- (void)authenticationDidFail;
- (void)authenticationDidCancel;
@end


@interface SPAuthenticator : NSObject

- (id)initWithDelegate:(id<SPAuthenticatorDelegate>)authDelegate simperium:(Simperium *)s;
- (BOOL)authenticateIfNecessary;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(SucceededBlockType)successBlock failure:(FailedBlockType)failureBlock;
- (void)createWithUsername:(NSString *)username password:(NSString *)password success:(SucceededBlockType)successBlock failure:(FailedBlockType)failureBlock;
- (void)reset;
- (void)cancel;

@end

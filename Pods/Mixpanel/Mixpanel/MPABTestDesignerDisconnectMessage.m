//
//  MPABTestDesignerDisconnectMessage.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 29/7/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPABTestDesignerDisconnectMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPVariant.h"

NSString *const MPABTestDesignerDisconnectMessageType = @"disconnect";

@implementation MPABTestDesignerDisconnectMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerDisconnectMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        MPVariant *variant = [connection sessionObjectForKey:kSessionVariantKey];
        if(variant) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [variant stop];
            });
        }

        conn.sessionEnded = YES;
        [conn close];
    }];
    return operation;
}

@end

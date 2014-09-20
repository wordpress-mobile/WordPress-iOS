//
//  MPABTestDesignerClearRequestMessage.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "MPABTestDesignerClearRequestMessage.h"
#import "MPABTestDesignerClearResponseMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPVariant.h"

NSString *const MPABTestDesignerClearRequestMessageType = @"clear_request";

@implementation MPABTestDesignerClearRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerClearRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        MPVariant *variant = [conn sessionObjectForKey:kSessionVariantKey];
        if (variant) {
            NSArray *actions = [self.payload objectForKey:@"actions"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                for (NSString *name in actions) {
                    [variant removeActionWithName:name];
                }
            });
        }

        MPABTestDesignerClearResponseMessage *clearResponseMessage = [MPABTestDesignerClearResponseMessage message];
        clearResponseMessage.status = @"OK";
        [conn sendMessage:clearResponseMessage];
    }];
    return operation;
}

@end

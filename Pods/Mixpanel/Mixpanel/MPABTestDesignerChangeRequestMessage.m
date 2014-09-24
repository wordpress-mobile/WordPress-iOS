//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerChangeRequestMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "MPABTestDesignerChangeResponseMessage.h"
#import "MPVariant.h"

NSString *const MPABTestDesignerChangeRequestMessageType = @"change_request";

@implementation MPABTestDesignerChangeRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerChangeRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        MPVariant *variant = [connection sessionObjectForKey:kSessionVariantKey];
        if (!variant) {
            variant = [[MPVariant alloc] init];
            [connection setSessionObject:variant forKey:kSessionVariantKey];
        }

        if ([[[self payload] objectForKey:@"actions"] isKindOfClass:[NSArray class]]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [variant addActionsFromJSONObject:[[self payload] objectForKey:@"actions"] andExecute:YES];
            });
        }

        MPABTestDesignerChangeResponseMessage *changeResponseMessage = [MPABTestDesignerChangeResponseMessage message];
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end

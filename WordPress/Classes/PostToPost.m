//
//  PostToPost.m
//  WordPress
//
//  Created by Maxime Biais on 17/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "PostToPost.h"
#import "BasePost.h"

@implementation PostToPost

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)destination
                                    entityMapping:(NSEntityMapping *)mapping
                                          manager:(NSMigrationManager *)manager
                                            error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    int remoteStatusNumber = [[destination valueForKey:@"remoteStatusNumber"] integerValue];
    if (remoteStatusNumber <= AbstractPostRemoteStatusFailed) {
        WPFLog(@"! Ignoring post with remoteStatus <= AbstractPostRemoteStatusFailed");
        return YES;
    }
    WPFLog(@"! incrementing remoteStatus > AbstractPostRemoteStatusFailed");
    [destination setValue:[NSNumber numberWithInt:remoteStatusNumber + 1] forKey:@"remoteStatusNumber"];
    return YES;
}

@end

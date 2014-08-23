//
//  Farm.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-10.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simperium.h"
#import "Config.h"
#import "SPBucket.h"

@interface Farm : NSObject <SimperiumDelegate, SPBucketDelegate>

@property (nonatomic, strong, readwrite) Simperium						*simperium;
@property (nonatomic, strong, readwrite) Config							*config;
@property (nonatomic, copy,   readwrite) NSString						*token;
@property (nonatomic, assign, readwrite) BOOL							done;
@property (nonatomic, assign, readwrite) int							expectedAcknowledgments;
@property (nonatomic, assign, readwrite) int							expectedAdditions;
@property (nonatomic, assign, readwrite) int							expectedDeletions;
@property (nonatomic, assign, readwrite) int							expectedChanges;
@property (nonatomic, assign, readwrite) int							expectedVersions;
@property (nonatomic, assign, readwrite) int							expectedIndexCompletions;
@property (nonatomic, strong, readonly)  NSManagedObjectContext			*managedObjectContext;
@property (nonatomic, strong, readonly)  NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, strong, readonly)  NSPersistentStoreCoordinator	*persistentStoreCoordinator;

- (id)initWithToken:(NSString *)token label:(NSString *)label;
- (void)start;
- (void)stop;
- (void)connect;
- (void)disconnect;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs;
- (BOOL)isDone;
- (void)resetExpectations;
- (void)logUnfulfilledExpectations;

@end


//
//  Simperium+Internals.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 12/11/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "SPCoreDataStorage.h"
#import "SPAuthenticator.h"
#import "SPLogger.h"
#import "SPJSONStorage.h"
#import "SPReachability.h"


#if TARGET_OS_IPHONE
#import "SPAuthenticationViewController.h"
#else
#import "SPAuthenticationWindowController.h"
#endif


#pragma mark ====================================================================================
#pragma mark Simperium: Private Methods
#pragma mark ====================================================================================

@interface Simperium() <SPStorageObserver, SPAuthenticatorDelegate, SPLoggerDelegate>

@property (nonatomic, strong) SPCoreDataStorage			*coreDataStorage;
@property (nonatomic, strong) SPJSONStorage				*JSONStorage;
@property (nonatomic, strong) NSMutableDictionary		*buckets;
@property (nonatomic, strong) id<SPNetworkInterface>	network;
@property (nonatomic, strong) SPRelationshipResolver	*relationshipResolver;
@property (nonatomic, strong) SPReachability			*reachability;
@property (nonatomic, strong) SPUser					*user;
@property (nonatomic,	copy) NSString					*clientID;
@property (nonatomic,	copy) NSString					*appID;
@property (nonatomic,	copy) NSString					*APIKey;
@property (nonatomic,	copy) NSString					*appURL;
@property (nonatomic,   copy) NSString					*label;
@property (nonatomic,   copy) NSDictionary              *bucketOverrides;
@property (nonatomic, assign) BOOL						skipContextProcessing;
@property (nonatomic, assign) BOOL						networkManagersStarted;
@property (nonatomic, assign) BOOL						dynamicSchemaEnabled;
@property (nonatomic, assign) BOOL						shouldSignIn;
@property (nonatomic, assign) BOOL						authenticationEnabled;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) SPAuthenticationViewController *authenticationViewController;
#else
@property (nonatomic, strong) SPAuthenticationWindowController *authenticationWindowController;
#endif

- (id)initWithModel:(NSManagedObjectModel *)model
			context:(NSManagedObjectContext *)context
		coordinator:(NSPersistentStoreCoordinator *)coordinator
			  label:(NSString *)label
    bucketOverrides:(NSDictionary *)bucketOverrides;

- (void)removeRemoteData;

@end


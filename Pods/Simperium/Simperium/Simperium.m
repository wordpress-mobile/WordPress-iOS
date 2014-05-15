//
//  Simperium.m
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "Simperium+Internals.h"
#import "SPUser.h"
#import "SPSchema.h"
#import "SPManagedObject.h"
#import "SPStorageObserver.h"
#import "SPMember.h"
#import "SPDiffer.h"
#import "SPGhost.h"
#import "SPEnvironment.h"
#import "SPWebSocketInterface.h"
#import "SPBucket+Internals.h"
#import "SPRelationshipResolver.h"
#import "JSONKit+Simperium.h"
#import "NSString+Simperium.h"
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Simperium: Constants
#pragma mark ====================================================================================

NSString * const UUID_KEY						= @"SPUUIDKey";
NSString * const SimperiumWillSaveNotification	= @"SimperiumWillSaveNotification";
NSTimeInterval const SPBackgroundSyncTimeout    = 20.0f;

#ifdef DEBUG
static SPLogLevels logLevel						= SPLogLevelsVerbose;
#else
static SPLogLevels logLevel						= SPLogLevelsInfo;
#endif


#pragma mark ====================================================================================
#pragma mark Simperium
#pragma mark ====================================================================================

@implementation Simperium

- (void)dealloc {
    [self stopNetworking];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
#if !TARGET_OS_IPHONE
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
#endif
}

#pragma mark - Constructors

- (id)initWithModel:(NSManagedObjectModel *)model
			context:(NSManagedObjectContext *)context
		coordinator:(NSPersistentStoreCoordinator *)coordinator {
	
	return [self initWithModel:model context:context coordinator:coordinator label:@"" bucketOverrides:nil];
}

- (id)initWithModel:(NSManagedObjectModel *)model
			context:(NSManagedObjectContext *)context
		coordinator:(NSPersistentStoreCoordinator *)coordinator
			  label:(NSString *)label
    bucketOverrides:(NSDictionary *)bucketOverrides {
	
	if ((self = [super init])) {
        
		self.label							= label;
        self.bucketOverrides                = bucketOverrides;
        self.networkEnabled					= YES;
        self.authenticationEnabled			= YES;
        self.dynamicSchemaEnabled			= YES;
		self.authenticationEnabled			= YES;
        self.buckets						= [NSMutableDictionary dictionary];
        
		SPWebSocketInterface *websocket		= [SPWebSocketInterface interfaceWithSimperium:self];
		self.network						= websocket;
		
        SPAuthenticator *auth				= [[SPAuthenticator alloc] initWithDelegate:self simperium:self];
        self.authenticator					= auth;
        
        SPRelationshipResolver *resolver	= [[SPRelationshipResolver alloc] init];
        self.relationshipResolver			= resolver;
		
		SPLogger *logger					= [SPLogger sharedInstance];
		logger.delegate						= self;
		
#if TARGET_OS_IPHONE
        self.authenticationViewControllerClass		= [SPAuthenticationViewController class];
#else
        self.authenticationWindowControllerClass	= [SPAuthenticationWindowController class];
#endif
		
		[self setupNotifications];
		
		[self setupCoreDataWithModelModel:model context:context coordinator:coordinator];
    }

	return self;
}


#pragma mark ====================================================================================
#pragma mark Init Helpers
#pragma mark ====================================================================================

- (void)setupNotifications {
#if !TARGET_OS_IPHONE
	NSNotificationCenter* wc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[wc addObserver:self selector:@selector(handleSleepNote:) name:NSWorkspaceWillSleepNotification object:NULL];
	[wc addObserver:self selector:@selector(handleWakeNote:)  name:NSWorkspaceDidWakeNotification   object:NULL];
#endif
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(authenticationDidFail) name:SPAuthenticationDidFail object:nil];

}

- (void)setupCoreDataWithModelModel:(NSManagedObjectModel *)model
							context:(NSManagedObjectContext *)context
						coordinator:(NSPersistentStoreCoordinator *)coordinator {
	
	NSParameterAssert(model);
	NSParameterAssert(context);
	NSParameterAssert(coordinator);
	
	NSAssert((context.concurrencyType == NSMainQueueConcurrencyType), NSLocalizedString(@"Error: you must initialize your context with 'NSMainQueueConcurrencyType' concurrency type.", nil));
	NSAssert((context.persistentStoreCoordinator == nil), NSLocalizedString(@"Error: NSManagedObjectContext's persistentStoreCoordinator must be nil. Simperium will handle CoreData connections for you.", nil));
	
	// Initialize CoreData
	SPCoreDataStorage* storage = [[SPCoreDataStorage alloc] initWithModel:model mainContext:context coordinator:coordinator];
	storage.delegate = self;
	self.coreDataStorage = storage;
	
	// Load the Buckets but don't start them yet
	NSArray *schemas = [storage exportSchemas];
	NSMutableDictionary *buckets = [self loadBuckets:schemas];
	self.buckets = buckets;
	
	// SPManagedObject's need the bucket list
	[storage setBucketList:buckets];
	
	// Load metadata for pending references among objects
	[self.relationshipResolver loadPendingRelationships:storage];
}


#pragma mark ====================================================================================
#pragma mark Bucket Helpers
#pragma mark ====================================================================================

- (SPBucket *)bucketForName:(NSString *)name { 
    SPBucket *bucket = self.buckets[name];
    if (!bucket) {
        // First check for an override
        for (SPBucket *someBucket in self.buckets.allValues) {
            if ([someBucket.remoteName isEqualToString:name]) {
                return bucket;
			}
        }
		
        // Lazily start buckets
        if (self.dynamicSchemaEnabled) {
            // Create and start a network manager for it
            SPSchema *schema = [[SPSchema alloc] initWithBucketName:name data:nil];
            schema.dynamic = YES;
						
			// New buckets use JSONStorage by default (you can't manually create a Core Data bucket)
			NSString *remoteName = self.bucketOverrides[schema.bucketName] ?: schema.bucketName;
			bucket = [[SPBucket alloc] initWithSchema:schema storage:self.JSONStorage networkInterface:self.network
								 relationshipResolver:self.relationshipResolver label:self.label remoteName:remoteName clientID:self.clientID];

			[self.buckets setObject:bucket forKey:name];
            [self.network start:bucket];
        }
    }
    
    return bucket;
}


#pragma mark ====================================================================================
#pragma mark Networking
#pragma mark ====================================================================================

- (void)startNetworkManagers {
    if (!self.networkEnabled || self.networkManagersStarted || !self.appID) {
        return;
	}
    
    SPLogInfo(@"Simperium starting network managers...");
    // Finally, start the network managers to start syncing data
    for (SPBucket *bucket in [self.buckets allValues]) {
        [bucket.network start:bucket];
	}
    self.networkManagersStarted = YES;
}

- (void)stopNetworkManagers {
    if (!self.networkManagersStarted) {
        return;
    }
	
    for (SPBucket *bucket in [self.buckets allValues]) {
        [bucket.network stop:bucket];
    }
	
    self.networkManagersStarted = NO;
}

- (void)startNetworking {
    // Create a new one each time to make sure it fires (and causes networking to start)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [SPReachability reachabilityWithHostName:SPReachabilityURL];
    [self.reachability startNotifier];
}

- (void)stopNetworking {
    [self stopNetworkManagers];
}

- (void)handleNetworkChange:(NSNotification *)notification {
	if ([self.reachability currentReachabilityStatus] == NotReachable) {
        [self stopNetworkManagers];
    } else if (self.user.authenticated) {
        [self startNetworkManagers];
    }
}

- (void)setNetworkEnabled:(BOOL)enabled {
    if (self.networkEnabled == enabled) {
        return;
    }
	
    _networkEnabled = enabled;
    if (enabled) {
        [self authenticateIfNecessary];
    } else {
        [self stopNetworking];
	}
}


#pragma mark ====================================================================================
#pragma mark Buckets
#pragma mark ====================================================================================

- (NSMutableDictionary *)loadBuckets:(NSArray *)schemas {
	NSAssert(schemas,				@"No schemas were provided");
	NSAssert(_network,				@"Network Interface should be initialized");
	NSAssert(_coreDataStorage,		@"CoreDataStorage should be initialized");
	NSAssert(_relationshipResolver,	@"CoreDataStorage should be initialized");
	
    NSMutableDictionary *bucketList = [NSMutableDictionary dictionaryWithCapacity:[schemas count]];
    SPBucket *bucket;

    for (SPSchema *schema in schemas) {
        
		NSString *remoteName = self.bucketOverrides[schema.bucketName] ?: schema.bucketName;
		bucket = [[SPBucket alloc] initWithSchema:schema storage:self.coreDataStorage networkInterface:self.network
							 relationshipResolver:self.relationshipResolver label:self.label remoteName:remoteName clientID:self.clientID];
        
        [bucketList setObject:bucket forKey:schema.bucketName];
    }
    
	[(SPWebSocketInterface *)self.network loadChannelsForBuckets:bucketList];
    
    return bucketList;
}

- (void)validateObjects {
    for (SPBucket *bucket in [self.buckets allValues]) {
        // Check all existing objects (e.g. in case there are existing ones that aren't in Simperium yet)
        [bucket validateObjects];
    }
    // No need to save, each bucket saves after validation
}

- (void)setAllBucketDelegates:(id)aDelegate {
    for (SPBucket *bucket in [self.buckets allValues]) {
        bucket.delegate = aDelegate;
    }
}

- (void)shareObject:(SPManagedObject *)object withEmail:(NSString *)email {
    SPBucket *bucket = [self.buckets objectForKey:object.bucket.name];
    [bucket.network shareObject: object withEmail:email];
}


#pragma mark ====================================================================================
#pragma mark Authentication Methods
#pragma mark ====================================================================================

#if TARGET_OS_IPHONE
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key rootViewController:(UIViewController *)controller {

	// Validate!
	if (!identifier) {
		[self failWithErrorCode:SPSimperiumErrorsMissingAppID];
		return;
	}
	
	if (!key) {
		[self failWithErrorCode:SPSimperiumErrorsMissingAPIKey];
		return;
	}
	
	if (!controller) {
		[self failWithErrorCode:SPSimperiumErrorsMissingWindow];
		return;
	}
	
	self.rootViewController = controller;
	[self startWithAppID:identifier APIKey:key];
}
#else
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key window:(NSWindow *)aWindow {
	
	// Validate!
	if (!identifier) {
		[self failWithErrorCode:SPSimperiumErrorsMissingAppID];
		return;
	}
	
	if (!key) {
		[self failWithErrorCode:SPSimperiumErrorsMissingAPIKey];
		return;
	}
	
	if (!aWindow) {
		[self failWithErrorCode:SPSimperiumErrorsMissingWindow];
		return;
	}
	
	// Hide the window right away
	self.window = aWindow;
	[self.window orderOut:nil];
	
	// Initialize + Authenticate
	[self startWithAppID:identifier APIKey:key];
}
#endif

- (void)authenticateWithAppID:(NSString *)identifier token:(NSString *)token {
	
	// Validate!
	if (!identifier) {
		[self failWithErrorCode:SPSimperiumErrorsMissingAppID];
		return;
	}
		
	if (!token) {
		[self failWithErrorCode:SPSimperiumErrorsMissingToken];
		return;
	}
		
	// Start Simperium: Disable Authentication!
	self.authenticationEnabled = NO;
	[self startWithAppID:identifier APIKey:nil];
	
	// Manually initialize the user
	self.user = [[SPUser alloc] initWithEmail:@"" token:token];
    [self startNetworkManagers];
}

- (void)shutdown {
	
}

- (void)startWithAppID:(NSString *)identifier APIKey:(NSString *)key {
	
	NSParameterAssert(identifier);
	
	SPLogInfo(@"Simperium starting... %@", self.label);
		
	// Keep the keys!
    self.appID		= identifier;
    self.APIKey		= key;
    self.rootURL	= SPBaseURL;
	
    // With everything configured, all objects can now be validated. This will pick up any objects that aren't yet
    // known to Simperium (for the case where you're adding Simperium to an existing app).
    [self validateObjects];
	
	// Handle authentication
	[self authenticateIfNecessary];
}


#pragma mark ====================================================================================
#pragma mark SPStorageObserver
#pragma mark ====================================================================================

- (void)storage:(id<SPStorageProvider>)storage updatedObjects:(NSSet *)updatedObjects insertedObjects:(NSSet *)insertedObjects deletedObjects:(NSSet *)deletedObjects {
    // This is automatically called by an SPStorage instance when data is locally changed and then saved

    // First deal with stashed objects (which are known to need a sync)
    NSMutableSet *unsavedObjects = [[storage stashedObjects] copy];

    // Unstash since they're about to be sent
    [storage unstashUnsavedObjects];
    
    for (id<SPDiffable>object in unsavedObjects) {
		if ( [[object class] conformsToProtocol:@protocol(SPDiffable)] ) {
			[object.bucket.network sendObjectChanges: object];
		}
    }
    
    // Send changes for all unsaved, inserted and updated objects
    // The changes will automatically get batched and synced in the next tick
    
    for (id<SPDiffable>insertedObject in insertedObjects) {
        if ([[insertedObject class] conformsToProtocol:@protocol(SPDiffable)]) {
            [insertedObject.bucket.network sendObjectChanges: insertedObject];
		}
    }
    
    for (id<SPDiffable>updatedObject in updatedObjects) {
        if ([[updatedObject class] conformsToProtocol:@protocol(SPDiffable)]) {
            [updatedObject.bucket.network sendObjectChanges: updatedObject];
		}
    }
    
    // Send changes for all deleted objects
    for (id<SPDiffable>deletedObject in deletedObjects) {
        if ([[deletedObject class] conformsToProtocol:@protocol(SPDiffable)]) {
            [deletedObject.bucket.network sendObjectDeletion: deletedObject];
            [deletedObject.bucket.storage stopManagingObjectWithKey:deletedObject.simperiumKey];
        }
    }
}


#pragma mark ====================================================================================
#pragma mark Core Data
#pragma mark ====================================================================================

- (BOOL)save {
    [self.JSONStorage save];
    [self.coreDataStorage save];
    return YES;
}

- (BOOL)saveWithoutSyncing {
    self.skipContextProcessing = YES;
    BOOL result = [self save];
    self.skipContextProcessing = NO;
    return result;
}

#if defined(__IPHONE_7_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0)

- (void)backgroundFetchWithCompletion:(SimperiumBackgroundFetchCompletion)completion {
    __block UIBackgroundFetchResult result  = UIBackgroundFetchResultNoData;
	dispatch_group_t group                  = dispatch_group_create();
    
	// Sync every bucket
	for (SPBucket* bucket in self.buckets.allValues) {
		dispatch_group_enter(group);
		[bucket forceSyncWithCompletion:^(BOOL signatureUpdated) {
            if (signatureUpdated) {
                result = UIBackgroundFetchResultNewData;
            }
			dispatch_group_leave(group);
		}];
	}

	// NOTE:
    // We have up to 30 seconds to complete this OP. If anything happens: slow network / broken pipe, and we don't hit the
    // delegate, we risk getting the app killed. As a safety measure, let's set a timeout.
    //
	__block BOOL notified   = NO;
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, SPBackgroundSyncTimeout * NSEC_PER_SEC);
    dispatch_block_t block  = ^{
		if (!notified) {
			completion(result);
			notified = YES;
		}
	};

	dispatch_group_notify(group, dispatch_get_main_queue(), block);
    dispatch_after(timeout, dispatch_get_main_queue(), block);
}

#endif


#if !TARGET_OS_IPHONE

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
	// Post Notification: Allow the client app to perform last minute changes
	[[NSNotificationCenter defaultCenter] postNotificationName:SimperiumWillSaveNotification object:self];
		
	// Proceed Saving!
	[self save];
	
	// Dispatch a NO-OP on the processorQueue's: we need to wait until they're empty
	dispatch_group_t group = dispatch_group_create();
	for (SPBucket* bucket in self.buckets.allValues) {
		dispatch_group_async(group, bucket.processorQueue, ^{ });
	}
	
	// When the queues are empty, the changes are expected to be saved locally
	dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
		[[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
	});
	
	// No matter what, delay App Termination:
	// there's no warranty that the processor's queues will be empty, even if the mainMOC has no changes
	return NSTerminateLater;
}

#endif


#pragma mark ====================================================================================
#pragma mark Signout Helpers
#pragma mark ====================================================================================

- (void)signOutAndRemoveLocalData:(BOOL)remove completion:(SimperiumSignoutCompletion)completion {
	
    // Don't proceed, if the user isn't logged in
    if (!self.user.authenticated) {
        return;
    }
    
    SPLogInfo(@"Simperium logging out...");
    
    // Reset Simperium: Don't start network managers again; expect app to handle that
    [self stopNetworking];
    
    // Reset the network manager and processors; any enqueued tasks will get skipped
	dispatch_group_t group = dispatch_group_create();
	
    for (SPBucket *bucket in self.buckets.allValues) {
		
		dispatch_group_enter(group);
        [bucket unloadAllObjects];
        [bucket.network reset:bucket completion:^(void) {
			dispatch_group_leave(group);
		}];
	}
		
	// Once every changeProcessor queue has been effectively, hit the completion callback
	dispatch_group_notify(group, dispatch_get_main_queue(), ^(void) {
		
		// Now delete all local content; no more changes will be coming in at this point
		if (remove) {
			SPLogInfo(@"Simperium clearing local data...");
			self.skipContextProcessing = YES;
			[self.buckets.allValues makeObjectsPerformSelector:@selector(deleteAllObjects)];
			self.skipContextProcessing = NO;
		}

		// Clear the token and user
		[self.authenticator reset];
		self.user = nil;

		// We just logged out. Let's display SignIn fields next time!
		self.shouldSignIn = YES;

		// Hit the delegate + callback
		if ([self.delegate respondsToSelector:@selector(simperiumDidLogout:)]) {
			[self.delegate simperiumDidLogout:self];
		}
		
		if (completion) {
			completion();
		}
	});
}


#pragma mark ====================================================================================
#pragma mark Properties
#pragma mark ====================================================================================

- (NSManagedObjectContext *)managedObjectContext {
    return self.coreDataStorage.mainManagedObjectContext;
}

- (NSManagedObjectContext *)writerManagedObjectContext {
    return self.coreDataStorage.writerManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    return self.coreDataStorage.managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    return self.coreDataStorage.persistentStoreCoordinator;
}

- (NSString *)clientID {
    if (!_clientID || _clientID.length == 0) {
        // Unique client ID; persist it so changes sent between sessions come from the same client ID
        NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:UUID_KEY];
        if (!uuid) {
            uuid = [NSString sp_makeUUID];
            [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:UUID_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        _clientID = [[NSString stringWithFormat:@"%@-%@", SPLibraryID, uuid] copy];
    }
    return _clientID;
}

- (void)setLabel:(NSString *)aLabel {
    _label = [aLabel copy];
    
    // Set the clientID as well, otherwise certain change operations won't work (since they'll appear to come from
    // the same Simperium instance)
    self.clientID = _label;
}

- (void)setRootURL:(NSString *)url {
    _rootURL = [url copy];
    self.appURL = [_rootURL stringByAppendingFormat:@"%@/", self.appID];
}

- (void)setVerboseLoggingEnabled:(BOOL)on {
    _verboseLoggingEnabled = on;
	[[SPLogger sharedInstance] setSharedLogLevel:on ? SPLogLevelsVerbose : SPLogLevelsWarn];
}

- (BOOL)objectsShouldSync {
    // TODO: rename or possibly (re)move this
    return !self.skipContextProcessing;
}


#pragma mark ====================================================================================
#pragma mark Authentication Helpers
#pragma mark ====================================================================================

- (void)authenticationDidSucceedForUsername:(NSString *)username token:(NSString *)token {
    
    // It's now safe to start the network managers
    [self startNetworking];
    
    [self closeAuthViewControllerAnimated:YES];
	
	if ([self.delegate respondsToSelector:@selector(simperiumDidLogin:)]) {
		[self.delegate simperiumDidLogin:self];
	}
}

- (void)authenticationDidCancel {
    [self stopNetworking];
    [self.authenticator reset];
    self.user.authToken = nil;
    [self closeAuthViewControllerAnimated:YES];
	
	if ([self.delegate respondsToSelector:@selector(simperiumDidCancelLogin:)]) {
		[self.delegate simperiumDidCancelLogin:self];
	}
}

- (void)authenticationDidFail {
    [self stopNetworking];
    [self.authenticator reset];
    self.user.authToken = nil;
    
    if (self.authenticationEnabled) {
        // Delay it a touch to avoid issues with storyboard-driven UIs
        [self performSelector:@selector(delayedOpenAuthViewController) withObject:nil afterDelay:0.1];
	}
}

- (BOOL)authenticateIfNecessary {
    if (!self.networkEnabled || !self.authenticationEnabled || !self.appID) {
        return NO;
	}
    
    [self stopNetworking];
    
    return [self.authenticator authenticateIfNecessary];    
}

- (void)delayedOpenAuthViewController {
    [self openAuthViewControllerAnimated:YES];
}

- (BOOL)isAuthVisible {
#if TARGET_OS_IPHONE
    // Login can either be its own root, or the first child of a nav controller if auth is optional
    NSArray *childViewControllers = self.rootViewController.presentedViewController.childViewControllers;
	BOOL isNotNil = (self.authenticationViewController != nil);
	BOOL isRoot = (self.rootViewController.presentedViewController == self.authenticationViewController);
    BOOL isChild = (childViewControllers.count > 0 && childViewControllers[0] == self.authenticationViewController);

    return (isNotNil && (isRoot || isChild));
#else
	return (self.authenticationWindowController != nil && self.authenticationWindowController.window.isVisible);
#endif
}

- (void)openAuthViewControllerAnimated:(BOOL)animated {
#if TARGET_OS_IPHONE
    if ([self isAuthVisible]) {
        return;
	}
	
    SPAuthenticationViewController *loginController = [[self.authenticationViewControllerClass alloc] init];
    loginController.authenticator       = self.authenticator;
    loginController.signingIn           = self.shouldSignIn;
    self.authenticationViewController   = loginController;
	
    if (!self.rootViewController) {
        UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
        self.rootViewController = [window rootViewController];
        NSAssert(self.rootViewController, @"Simperium error: to use built-in authentication, you must configure a rootViewController when you "
										   "initialize Simperium, or call setParentViewControllerForAuthentication:. "
										   "This is how Simperium knows where to present a modal view. See enableManualAuthentication in the "
										   "documentation if you want to use your own authentication interface.");
    }
    
    UIViewController *controller = self.authenticationViewController;
    UINavigationController *navController = nil;
    if (self.authenticationOptional) {
        navController = [[UINavigationController alloc] initWithRootViewController: self.authenticationViewController];
        controller = navController;
    }
    
	[self.rootViewController presentViewController:controller animated:animated completion:nil];
#else
    if (!self.authenticationWindowController) {
        self.authenticationWindowController					= [[self.authenticationWindowControllerClass alloc] init];
        self.authenticationWindowController.authenticator	= self.authenticator;
        self.authenticationWindowController.optional		= self.authenticationOptional;
        self.authenticationWindowController.signingIn		= self.shouldSignIn;
    }
    
    // Hide the main window and show the auth window instead
    [self.window setIsVisible:NO];    
    [[self.authenticationWindowController window] center];
    [[self.authenticationWindowController window] makeKeyAndOrderFront:self];
#endif
}

- (void)closeAuthViewControllerAnimated:(BOOL)animated {
#if TARGET_OS_IPHONE
    // Login can either be its own root, or the first child of a nav controller if auth is optional
    if ([self isAuthVisible]) {
        [self.rootViewController dismissViewControllerAnimated:animated completion:nil];
	}
    self.authenticationViewController = nil;
#else
    [self.window setIsVisible:YES];
    [[self.authenticationWindowController window] close];
    self.authenticationWindowController = nil;
#endif
}


#pragma mark ====================================================================================
#pragma mark OSX System Wake/Sleep Handlers
#pragma mark ====================================================================================

#if !TARGET_OS_IPHONE
- (void)handleSleepNote:(NSNotification *)note {
	SPLogVerbose(@"<> OSX Sleep: Stopping Network Managers");
	
	[self stopNetworkManagers];
}

- (void)handleWakeNote:(NSNotification *)note {
	SPLogVerbose(@"<> OSX WakeUp: Restarting Network Managers");
	
	if (self.user.authenticated) {
        [self startNetworkManagers];
	}
}
#endif


#pragma mark ====================================================================================
#pragma mark SPSimperiumLoggerDelegate
#pragma mark ====================================================================================

- (void)handleLogMessage:(NSString*)logMessage {
	if (!self.remoteLoggingEnabled) {
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.network sendLogMessage:logMessage];
	});
}


#pragma mark ====================================================================================
#pragma mark Private Methods
#pragma mark ====================================================================================

- (void)removeRemoteData {
	// Note: this method should only be used by the Integration Tests. Will only delete the remote data
    for (SPBucket *bucket in [self.buckets allValues]) {
		[bucket.network removeAllBucketObjects:bucket];
	}
}

- (void)failWithErrorCode:(SPSimperiumErrors)code {
	if (![self.delegate respondsToSelector:@selector(simperium:didFailWithError:)]) {
		return;
	}
	
	NSError* error = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:nil];
	[self.delegate simperium:self didFailWithError:error];
}

@end

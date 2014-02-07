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
#import "SPBinaryManager.h"
#import "SPStorageObserver.h"
#import "SPMember.h"
#import "SPMemberBinary.h"
#import "SPDiffer.h"
#import "SPGhost.h"
#import "SPEnvironment.h"
#import "SPWebSocketInterface.h"
#import "SPBucket+Internals.h"
#import "SPRelationshipResolver.h"
#import "JSONKit+Simperium.h"
#import "NSString+Simperium.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger+Simperium.h"



#pragma mark ====================================================================================
#pragma mark Simperium: Constants
#pragma mark ====================================================================================

NSString * const UUID_KEY						= @"SPUUIDKey";
NSString * const SimperiumWillSaveNotification	= @"SimperiumWillSaveNotification";


#pragma mark ====================================================================================
#pragma mark Simperium
#pragma mark ====================================================================================

@implementation Simperium

#ifdef DEBUG
static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static int ddLogLevel = LOG_LEVEL_INFO;
#endif

+ (int)ddLogLevel {
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel {
    ddLogLevel = logLevel;
}

+ (void)setupLogging {
	// Handle multiple Simperium instances by ensuring logging only gets started once
    static dispatch_once_t _once;
    dispatch_once(&_once, ^{
		[DDLog addLogger:[DDASLLogger sharedInstance]];
		[DDLog addLogger:[DDTTYLogger sharedInstance]];
		[DDLog addLogger:[DDFileLogger sharedInstance]];
		[DDLog addLogger:[SPSimperiumLogger sharedInstance]];
	});
}

- (void)dealloc {
    [self stopNetworking];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
#if !TARGET_OS_IPHONE
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
#endif
}

#pragma mark - Constructors
- (id)init {
	if ((self = [super init])) {

        [[self class] setupLogging];
        
        self.label = @"";
        self.networkEnabled = YES;
        self.authenticationEnabled = YES;
        self.dynamicSchemaEnabled = YES;
        self.buckets = [NSMutableDictionary dictionary];
        
        SPAuthenticator *auth = [[SPAuthenticator alloc] initWithDelegate:self simperium:self];
        self.authenticator = auth;
        
        SPRelationshipResolver *resolver = [[SPRelationshipResolver alloc] init];
        self.relationshipResolver = resolver;

		SPSimperiumLogger *logger = [SPSimperiumLogger sharedInstance];
		logger.delegate = self;
		
#if TARGET_OS_IPHONE
        self.authenticationViewControllerClass = [SPAuthenticationViewController class];
#else
        self.authenticationWindowControllerClass = [SPAuthenticationWindowController class];
#endif
		
#if !TARGET_OS_IPHONE
		NSNotificationCenter* wc = [[NSWorkspace sharedWorkspace] notificationCenter];
		[wc addObserver:self selector:@selector(handleSleepNote:) name:NSWorkspaceWillSleepNotification object: NULL];
		[wc addObserver:self selector:@selector(handleWakeNote:) name:NSWorkspaceDidWakeNotification object: NULL];
#endif
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(authenticationDidFail) name:SPAuthenticationDidFail object:nil];
    }

	return self;
}

#if TARGET_OS_IPHONE
- (id)initWithRootViewController:(UIViewController *)controller {
    if ((self = [self init])) {
        self.rootViewController = controller;
    }
    
    return self;
}
#else
- (id)initWithWindow:(NSWindow *)aWindow {
    if ((self = [self init])) {
        self.window = aWindow;
        
        // Hide window by default - authenticating will make it visible
        [self.window orderOut:nil];
    }
    
    return self;
}
#endif


- (void)configureBinaryManager:(SPBinaryManager *)manager {    
    // Binary members need to know about the manager (ugly but avoids singleton/global)
    for (SPBucket *bucket in [self.buckets allValues]) {
        for (SPMemberBinary *binaryMember in bucket.differ.schema.binaryMembers) {
            binaryMember.binaryManager = manager;
        }
    }
}

- (NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName {
    return [self.binaryManager addBinary:binaryData toObject:object bucketName:bucketName attributeName:attributeName];
}

- (void)addBinaryWithFilename:(NSString *)filename toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName {
    // Make sure the object has a simperiumKey (it might not if it was just created)
    if (!object.simperiumKey)
        object.simperiumKey = [NSString sp_makeUUID];
    return [self.binaryManager addBinaryWithFilename:filename toObject:object bucketName:bucketName attributeName:attributeName];
}

- (NSData *)dataForFilename:(NSString *)filename {
    return [self.binaryManager dataForFilename:filename];
}

- (SPBucket *)bucketForName:(NSString *)name { 
    SPBucket *bucket = [self.buckets objectForKey:name];
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
								 relationshipResolver:self.relationshipResolver label:self.label remoteName:remoteName];

			[self.buckets setObject:bucket forKey:name];
            [self.network start:bucket];
        }
    }
    
    return bucket;
}

- (NSData*)exportLogfiles {
	return [[DDFileLogger sharedInstance] exportLogfiles];
}


#pragma mark ====================================================================================
#pragma mark Networking
#pragma mark ====================================================================================

- (void)startNetworkManagers {
    if (!self.networkEnabled || self.networkManagersStarted) {
        return;
	}
    
    DDLogInfo(@"Simperium starting network managers...");
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
    NSMutableDictionary *bucketList = [NSMutableDictionary dictionaryWithCapacity:[schemas count]];
    SPBucket *bucket;

    for (SPSchema *schema in schemas) {
//        Class entityClass = NSClassFromString(schema.bucketName);
//        NSAssert1(entityClass != nil, @"Simperium error: couldn't find a class mapping for: ", schema.bucketName);
        
		NSString *remoteName = self.bucketOverrides[schema.bucketName] ?: schema.bucketName;
		bucket = [[SPBucket alloc] initWithSchema:schema storage:self.coreDataStorage networkInterface:self.network
							 relationshipResolver:self.relationshipResolver label:self.label remoteName:remoteName];
        
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
#pragma mark Initialization
#pragma mark ====================================================================================

/*
- (void)startWithAppID:(NSString *)identifier APIKey:(NSString *)key {
    DDLogInfo(@"Simperium starting... %@", self.label);
	
	// Enforce required parameters
	NSParameterAssert(identifier);
	NSParameterAssert(key);
	
	// Keep the keys!
    self.appID = identifier;
    self.APIKey = key;
    self.rootURL = SPBaseURL;
    
	// Setup the Network
	SPWebSocketInterface *websocket = [SPWebSocketInterface interfaceWithSimperium:self appURL:self.appURL clientID:self.clientID];;
	self.network = websocket;
	
    // Setup JSON storage
    SPJSONStorage *storage = [[SPJSONStorage alloc] initWithDelegate:self];
    self.JSONStorage = storage;
    
    // Network managers (load but don't start yet)
    //[self loadNetworkManagers];
    
    // Check all existing objects (e.g. in case there are existing ones that aren't in Simperium yet)
    //    [objectManager validateObjects];
    
    if (self.authenticationEnabled) {
        [self authenticateIfNecessary];
    }
}
*/

- (void)startWithAppID:(NSString *)identifier APIKey:(NSString *)key model:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator {
	DDLogInfo(@"Simperium starting... %@", self.label);
	
	// Enforce required parameters
	NSParameterAssert(identifier);
	NSParameterAssert(key);
	NSParameterAssert(model);
	NSParameterAssert(context);
	NSParameterAssert(coordinator);
	
	NSAssert((context.concurrencyType == NSMainQueueConcurrencyType), NSLocalizedString(@"Error: you must initialize your context with 'NSMainQueueConcurrencyType' concurrency type.", nil));
	NSAssert((context.persistentStoreCoordinator == nil), NSLocalizedString(@"Error: NSManagedObjectContext's persistentStoreCoordinator must be nil. Simperium will handle CoreData connections for you.", nil));
	
	// Keep the keys!
    self.appID = identifier;
    self.APIKey = key;
    self.rootURL = SPBaseURL;
    
	// Setup the Network
	SPWebSocketInterface *websocket = [SPWebSocketInterface interfaceWithSimperium:self appURL:self.appURL clientID:self.clientID];;
	self.network = websocket;
	
    // Setup Core Data storage
    SPCoreDataStorage *storage = [[SPCoreDataStorage alloc] initWithModel:model mainContext:context coordinator:coordinator];
    self.coreDataStorage = storage;
    self.coreDataStorage.delegate = self;
    
    // Get the schema from Core Data    
    NSArray *schemas = [self.coreDataStorage exportSchemas];
    
    // Load but don't start yet
    self.buckets = [self loadBuckets:schemas];
    
    // Each NSManagedObject stores a reference to the bucket in which it's stored
    [self.coreDataStorage setBucketList: self.buckets];
    
    // Load metadata for pending references among objects
    [self.relationshipResolver loadPendingRelationships:self.coreDataStorage];
    
    if (self.binaryManager) {
        [self configureBinaryManager:self.binaryManager];
	}
    
    // With everything configured, all objects can now be validated. This will pick up any objects that aren't yet
    // known to Simperium (for the case where you're adding Simperium to an existing app).
    [self validateObjects];
                            
    if (self.authenticationEnabled) {
        [self authenticateIfNecessary];
    }    
}

- (void)shutdown {
	
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

- (void)forceSyncWithTimeout:(NSTimeInterval)timeoutSeconds completion:(SimperiumForceSyncCompletion)completion {
	dispatch_group_t group = dispatch_group_create();
	__block BOOL notified = NO;
	
	// Sync every bucket
	for (SPBucket* bucket in self.buckets.allValues) {
		dispatch_group_enter(group);
		[bucket forceSyncWithCompletion:^() {
			dispatch_group_leave(group);
		}];
	}

	// Wait until the workers are ready
	dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
		if (!notified) {
			completion(YES);
			notified = YES;
		}
	});
	
	// Notify anyways after timeout
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeoutSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		if (!notified) {
			completion(NO);
			notified = YES;
		}
    });
}

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
#pragma mark Manual Authentication
#pragma mark ====================================================================================

- (void)authenticateWithToken:(NSString *)token {

	// User's email will be loaded during auth mechanism, if successful
	self.user = [[SPUser alloc] initWithEmail:@"" token:token];
    [self startNetworkManagers];
}

- (void)signOutAndRemoveLocalData:(BOOL)remove {
    DDLogInfo(@"Simperium clearing local data...");
    
    // Reset Simperium: Don't start network managers again; expect app to handle that
    [self stopNetworking];
    
    // Reset the network manager and processors; any enqueued tasks will get skipped
    for (SPBucket *bucket in [self.buckets allValues]) {
        [bucket unloadAllObjects];
        
        // This will block until everything is all clear
        [bucket.network resetBucketAndWait:bucket];
    }
    
    // Now delete all local content; no more changes will be coming in at this point
    if (remove) {
        self.skipContextProcessing = YES;
        for (SPBucket *bucket in [self.buckets allValues]) {
            [bucket deleteAllObjects];
        }
        self.skipContextProcessing = NO;
    }
    
    // Clear the token and user
    [self.authenticator reset];
    self.user = nil;

	// We just logged out. Let's display SignIn fields next time!
	self.shouldSignIn = YES;
	
	// Hit the delegate
	if ([self.delegate respondsToSelector:@selector(simperiumDidLogout:)]) {
		[self.delegate simperiumDidLogout:self];
	}
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
    for (Class cls in [DDLog registeredClasses]) {
        [DDLog setLogLevel:on ? LOG_LEVEL_VERBOSE : LOG_LEVEL_INFO forClass:cls];
    }
}

- (BOOL)objectsShouldSync {
    // TODO: rename or possibly (re)move this
    return !self.skipContextProcessing;
}


#pragma mark ====================================================================================
#pragma mark Authentication
#pragma mark ====================================================================================

- (void)authenticationDidSucceedForUsername:(NSString *)username token:(NSString *)token {
    [self.binaryManager setupAuth:self.user];
    
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
    if (!self.networkEnabled || !self.authenticationEnabled) {
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
	
    SPAuthenticationViewController *loginController		= [[self.authenticationViewControllerClass alloc] init];
    self.authenticationViewController					= loginController;
    self.authenticationViewController.authenticator		= self.authenticator;
    self.authenticationViewController.signingIn			= self.shouldSignIn;
	
    if (!self.rootViewController) {
        UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
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
	DDLogVerbose(@"<> OSX Sleep: Stopping Network Managers");
	
	[self stopNetworkManagers];
}

- (void)handleWakeNote:(NSNotification *)note {
	DDLogVerbose(@"<> OSX WakeUp: Restarting Network Managers");
	
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

@end

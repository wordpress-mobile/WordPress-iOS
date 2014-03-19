//
//  SPWebSocketManager
//  Simperium
//
//  Created by Michael Johnston on 11-03-07.
//  Copyright 2011 Simperium. All rights reserved.
//
#import "SPWebSocketInterface.h"
#import "Simperium+Internals.h"
#import "SPChangeProcessor.h"
#import "SPUser.h"
#import "SPBucket+Internals.h"
#import "JSONKit+Simperium.h"
#import "NSString+Simperium.h"
#import "SPLogger.h"
#import "SPWebSocket.h"
#import "SPWebSocketChannel.h"
#import "SPEnvironment.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSTimeInterval const SPWebSocketHeartbeatInterval	= 30;

NSString * const COM_AUTH							= @"auth";
NSString * const COM_INDEX							= @"i";
NSString * const COM_CHANGE							= @"c";
NSString * const COM_CHANGE_VERSION					= @"cv";
NSString * const COM_ENTITY							= @"e";
NSString * const COM_ERROR							= @"?";
NSString * const COM_LOG							= @"log";
NSString * const COM_INDEX_STATE					= @"index";
NSString * const COM_HEARTBEAT						= @"h";
NSString * const COM_OPTIONS						= @"o";

static SPLogLevels logLevel							= SPLogLevelsInfo;

typedef NS_ENUM(NSInteger, SPRemoteLogging) {
	SPRemoteLoggingOff		= 0,
	SPRemoteLoggingRegular	= 1,
	SPRemoteLoggingVerbose	= 2
};


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPWebSocketInterface() <SRWebSocketDelegate>
@property (nonatomic, strong, readwrite) SPWebSocket			*webSocket;
@property (nonatomic, weak,   readwrite) Simperium				*simperium;
@property (nonatomic, strong, readwrite) NSMutableDictionary	*channels;
@property (nonatomic, strong, readwrite) NSTimer				*heartbeatTimer;
@property (nonatomic, strong, readwrite) NSTimer				*timeoutTimer;
@property (nonatomic, assign, readwrite) BOOL					open;
@end


#pragma mark ====================================================================================
#pragma mark SPWebSocketInterface
#pragma mark ====================================================================================

@implementation SPWebSocketInterface

- (id)initWithSimperium:(Simperium *)s {
	if ((self = [super init])) {
        self.simperium = s;
        self.channels = [NSMutableDictionary dictionaryWithCapacity:20];
	}
	
	return self;
}

- (SPWebSocketChannel *)channelForName:(NSString *)str {
    return [self.channels objectForKey:str];
}

- (SPWebSocketChannel *)channelForNumber:(NSNumber *)num {
    for (SPWebSocketChannel *channel in [self.channels allValues]) {
        if ([num intValue] == channel.number) {
            return channel;
		}
    }
    return nil;
}

- (SPWebSocketChannel *)loadChannelForBucket:(SPBucket *)bucket {
    int channelNumber = (int)[self.channels count];
    SPWebSocketChannel *channel = [SPWebSocketChannel channelWithSimperium:self.simperium];
    channel.number = channelNumber;
    channel.name = bucket.name;
	channel.remoteName = bucket.remoteName;
    [self.channels setObject:channel forKey:bucket.name];
    
    return [self.channels objectForKey:bucket.name];
}

- (void)loadChannelsForBuckets:(NSDictionary *)bucketList {
    for (SPBucket *bucket in [bucketList allValues]) {
        [self loadChannelForBucket:bucket];
	}
}

- (void)startChannels {
    for (SPWebSocketChannel *channel in [self.channels allValues]) {
        channel.webSocketManager = self;
        [self authenticateChannel:channel];
    }
}

- (void)stopChannels {
    for (SPWebSocketChannel *channel in [self.channels allValues]) {
        channel.started = NO;
    }
}

- (void)sendObjectDeletion:(id<SPDiffable>)object {
    SPWebSocketChannel *channel = [self channelForName:object.bucket.name];
    [channel sendObjectDeletion:object];
}

- (void)sendObjectChanges:(id<SPDiffable>)object {
    SPWebSocketChannel *channel = [self channelForName:object.bucket.name];
    [channel sendObjectChanges:object];
}

- (void)removeAllBucketObjects:(SPBucket *)bucket {
    SPWebSocketChannel *channel = [self channelForName:bucket.name];
	[channel removeAllBucketObjects:bucket];
}

- (void)sendLogMessage:(NSString*)logMessage {
	NSDictionary *payload = @{ @"log" : logMessage };
	NSString *message = [NSString stringWithFormat:@"%@:%@", COM_LOG, [payload sp_JSONString]];
	[self send:message];
}

- (void)authenticateChannel:(SPWebSocketChannel *)channel {
    //    NSString *message = @"1:command:parameters";

    NSDictionary *jsonData = @{
		@"api"		: @(SPAPIVersion.floatValue),
		@"clientid"	: self.simperium.clientID,
		@"app_id"	: self.simperium.appID,
		@"token"	: self.simperium.user.authToken,
		@"name"		: channel.remoteName,
		@"library"	: SPLibraryID,
		@"version"	: SPLibraryVersion
	};
    
    SPLogVerbose(@"Simperium initializing websocket channel %d:%@", channel.number, jsonData);
    NSString *message = [NSString stringWithFormat:@"%d:init:%@", channel.number, [jsonData sp_JSONString]];
    [self send:message];
}


- (void)openWebSocket {
	// Prevent multiple 'openWebSocket' calls to get executed
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(openWebSocket) object:nil];
	
	// Open the socket!
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/websocket", SPWebsocketURL, self.simperium.appID];
    SPWebSocket *newWebSocket = [[SPWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    self.webSocket = newWebSocket;
    self.webSocket.delegate = self;
    self.open = NO;
	
    SPLogVerbose(@"Simperium opening WebSocket connection...");
    [self.webSocket open];
}

- (void)start:(SPBucket *)bucket {
    SPWebSocketChannel *channel = [self channelForName:bucket.name];
    if (!channel) {
        channel = [self loadChannelForBucket:bucket];
    }
	
    if (channel.started) {
        return;
    }
	
    if (self.webSocket == nil) {
        [self openWebSocket];
        // Channels will get setup after successfully connection
    } else if (self.open) {
        [self authenticateChannel:channel];
    }
}

- (void)stop:(SPBucket *)bucket {
    SPWebSocketChannel *channel = [self channelForName:bucket.name];
    channel.started = NO;
    channel.webSocketManager = nil;
    
    // Can't remove the channel because it's needed for offline changes; this is weird and should be fixed
    //[channels removeObjectForKey:bucket.name];
	
    SPLogVerbose(@"Simperium stopping network manager (%@)", bucket.name);
    
    // Mark it closed so it doesn't reopen
    self.open = NO;
    [self.webSocket close];
	self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    // TODO: Consider ensuring threads are done their work and sending a notification
}

- (void)reset:(SPBucket *)bucket completion:(SPNetworkInterfaceResetCompletion)completion {
	// Note: Let's prevent any death lock scenarios. This call should be sync, and we'll hit the callback when appropiate
    dispatch_async(bucket.processorQueue, ^{
        [bucket.changeProcessor reset];
		[bucket setLastChangeSignature:nil];
		
		if (completion) {
			completion();
		}
    });
}

- (void)send:(NSString *)message {
	if (!self.open) {
		return;
	}
    [self.webSocket send:message];
    [self resetHeartbeatTimer];
}


#pragma mark - Heatbeat Helpers

- (void)resetHeartbeatTimer {
	[self.heartbeatTimer invalidate];
	self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:SPWebSocketHeartbeatInterval target:self selector:@selector(sendHeartbeat:) userInfo:nil repeats:NO];
}

- (void)sendHeartbeat:(NSTimer *)timer {
    if (self.webSocket.readyState != SR_OPEN) {
		return;
	}
	
	// Send it (will also schedule another one)
	// NSLog(@">> Simperium sending heartbeat");
	[self send:@"h:1"];
}


#pragma mark - SRWebSocketDelegate Methods

- (void)webSocketDidOpen:(SRWebSocket *)theWebSocket {
	// Reconnection failsafe
	if ( theWebSocket != (SRWebSocket*)self.webSocket) {
		return;
	}
	
    self.open = YES;
    [self startChannels];
    [self resetHeartbeatTimer];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	[self stopChannels];
	self.webSocket.delegate = nil;
    self.webSocket = nil;
    self.open = NO;
	
	// Network enabled = YES: There was a networking glitch, yet, reachability flags are OK. We should retry
    if (self.simperium.networkEnabled) {
		SPLogVerbose(@"Simperium websocket failed (will retry) with error %@", error);
		[self performSelector:@selector(openWebSocket) withObject:nil afterDelay:2];
	// Otherwise, the device lost reachability, and the interfaces were shut down by the framework
	} else {
		SPLogVerbose(@"Simperium websocket failed (will NOT retry) with error %@", error);
	}
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
			
	// Parse!
    NSRange range = [message rangeOfString:@":"];
    
    if (range.location == NSNotFound) {
        SPLogError(@"Simperium websocket received invalid message: %@", message);
        return;
    }
    
	// Handle Messages:
	//		- [CHANNEL:COMMAND]
    NSString *channelStr = [message substringToIndex:range.location];
    NSString *commandStr = [message substringFromIndex:range.location+range.length];
	
    // Message: Heartbeat
    if ([channelStr isEqualToString:COM_HEARTBEAT]) {
        //SPLogVerbose(@"Simperium heartbeat acknowledged");
        return;
    }
    
	// Message: LogLevel
	if ([channelStr isEqualToString:COM_LOG]) {
		SPLogVerbose(@"Simperium (%@) Received Remote LogLevel %@", self.simperium.label, commandStr);
		NSInteger logLevel = commandStr.intValue;
		self.simperium.remoteLoggingEnabled	 = (logLevel != SPRemoteLoggingOff);
		self.simperium.verboseLoggingEnabled = (logLevel == SPRemoteLoggingVerbose);
		return;
	}
			
    SPLogVerbose(@"Simperium (%@) received \"%@\"", self.simperium.label, message);
    
    // Load the WebsocketChannel + Bucket
    NSNumber *channelNumber		= @(channelStr.intValue);
    SPWebSocketChannel *channel = [self channelForNumber:channelNumber];
    SPBucket *bucket			= [self.simperium bucketForName:channel.name];
    
	// Message: Remote Index Request
	if ([commandStr isEqualToString:COM_INDEX_STATE]) {
		[channel handleIndexStatusRequest:bucket];
		return;
	}
	
	// Handle Messages:
	//		- [CHANNEL:COMMAND:DATA]
    range = [commandStr rangeOfString:@":"];
    if (range.location == NSNotFound) {
        SPLogWarn(@"Simperium received unrecognized websocket message: %@", message);
    }
	
    NSString *command	= [commandStr substringToIndex:range.location];
    NSString *data		= [commandStr substringFromIndex:range.location+range.length];
    
    if ([command isEqualToString:COM_AUTH]) {
		[channel handleAuthResponse:data bucket:bucket];
    } else if ([command isEqualToString:COM_INDEX]) {
        [channel handleIndexResponse:data bucket:bucket];
    } else if ([command isEqualToString:COM_CHANGE_VERSION]) {
		// Handle cv:? message: the requested change version didn't exist, so re-index
		SPLogVerbose(@"Simperium change version is out of date (%@), re-indexing", bucket.name);
		[channel requestLatestVersionsForBucket:bucket];
	} else if ([command isEqualToString:COM_CHANGE]) {
		// Incoming changes, handle them
		NSArray *changes = [data sp_objectFromJSONString];
		[channel handleRemoteChanges: changes bucket:bucket];
    } else if ([command isEqualToString:COM_ENTITY]) {
        [channel handleVersionResponse:data bucket:bucket];
	} else if ([command isEqualToString:COM_OPTIONS]) {
		[channel handleOptions:data bucket:bucket];
    } else if ([command isEqualToString:COM_ERROR]) {
        SPLogVerbose(@"Simperium returned a command error (?) for bucket %@", bucket.name);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if (self.open) {
        // Closed unexpectedly, retry
        [self performSelector:@selector(openWebSocket) withObject:nil afterDelay:2];
        SPLogVerbose(@"Simperium connection closed (will retry): %ld, %@", (long)code, reason);
    } else {
        // Closed on purpose
        SPLogInfo(@"Simperium connection closed");
    }

	[self stopChannels];
	self.webSocket.delegate = nil;
    self.webSocket = nil;
    self.open = NO;
}


#pragma mark - Public Methods

- (void)requestVersions:(int)numVersions object:(id<SPDiffable>)object {
    SPWebSocketChannel *channel = [self channelForName:object.bucket.name];
    [channel requestVersions:numVersions object:object];
}

- (void)shareObject:(id<SPDiffable>)object withEmail:(NSString *)email {
    SPWebSocketChannel *channel = [self channelForName:object.bucket.name];
    [channel shareObject:object withEmail:email];
}

- (void)requestLatestVersionsForBucket:(SPBucket *)b {
    SPWebSocketChannel *channel = [self channelForName:b.name];
    [channel requestLatestVersionsForBucket:b];
}

- (void)forceSyncBucket:(SPBucket *)bucket {
	// Let's reuse the start mechanism. This will post the latest CV + publish pending changes
	SPWebSocketChannel *channel = [self channelForName:bucket.name];
	[channel startProcessingChangesForBucket:bucket];
}


#pragma mark Static Helpers:
#pragma mark MockWebSocketInterface relies on this mechanism to register itself, while running the Unit Testing target

static Class _class;

+ (void)load {
	_class = [SPWebSocketInterface class];
}

+ (void)registerClass:(Class)c {
	_class = c;
}

+ (instancetype)interfaceWithSimperium:(Simperium *)s {
	return [[_class alloc] initWithSimperium:s];
}

@end

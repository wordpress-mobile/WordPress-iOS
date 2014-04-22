//
//  SPPersistentMutableSet.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/14/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPPersistentMutableSet.h"
#import "JSONKit+Simperium.h"
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel	= SPLogLevelsError;


#pragma mark ====================================================================================
#pragma mark Private Methods
#pragma mark ====================================================================================

@interface SPPersistentMutableSet ()
@property (nonatomic, strong, readwrite) NSString			*label;
@property (nonatomic, strong, readwrite) NSURL				*mutableSetURL;
@property (nonatomic, strong, readwrite) NSMutableSet		*contents;
@property (nonatomic, strong, readwrite) dispatch_queue_t	setQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t	saveQueue;
@property (nonatomic, assign, readwrite) BOOL				needsSave;
@end


#pragma mark ====================================================================================
#pragma mark SPMutableSetStorage
#pragma mark ====================================================================================

@implementation SPPersistentMutableSet

- (id)initWithLabel:(NSString *)label {
	if ((self = [super init])) {
		self.label		= label;
		self.contents	= [NSMutableSet setWithCapacity:3];
        self.setQueue	= dispatch_queue_create("com.simperium.SPPersistentMutableSet.SetQueue", NULL);
        self.saveQueue	= dispatch_queue_create("com.simperium.SPPersistentMutableSet.SaveQueue", NULL);
	}
	
	return self;
}

- (void)addObject:(id)object {
	dispatch_async(self.setQueue, ^{
		[self.contents addObject:object];
		self.needsSave = YES;
	});
}

- (void)removeObject:(id)object {
	dispatch_async(self.setQueue, ^{
		[self.contents removeObject:object];
		self.needsSave = YES;
	});
}

- (NSArray *)allObjects {
	__block NSArray *objects = nil;
	dispatch_sync(self.setQueue, ^{
		objects = self.contents.allObjects;
	});
	return objects;
}

- (NSSet *)copyInnerSet {
	__block NSSet *objects = nil;
	dispatch_sync(self.setQueue, ^{
		objects = [self.contents copy];
	});
	return objects;
}

- (NSUInteger)count {
	__block NSUInteger count;
	dispatch_sync(self.setQueue, ^{
		count = self.contents.count;
	});
	return count;
}

- (void)addObjectsFromArray:(NSArray *)array {
	dispatch_async(self.setQueue, ^{
		[self.contents addObjectsFromArray:array];
		self.needsSave = YES;
	});
}

- (void)minusSet:(NSSet *)otherSet {
	dispatch_async(self.setQueue, ^{
		[self.contents minusSet:otherSet];
		self.needsSave = YES;
	});
}

- (void)removeAllObjects {
	dispatch_async(self.setQueue, ^{
		[self.contents removeAllObjects];
		self.needsSave = YES;
	});
}


#pragma mark ====================================================================================
#pragma mark NSFastEnumeration
#pragma mark ====================================================================================

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len  {
    __block NSUInteger count;
	dispatch_sync(self.setQueue, ^{
        count = [self.contents countByEnumeratingWithState:state objects:buffer count:len];
    });
    
    return count;
}


#pragma mark ====================================================================================
#pragma mark Persistance!
#pragma mark ====================================================================================

- (void)save {
	[self saveAndWait:NO];
}

- (void)saveAndWait:(BOOL)wait {
	
	dispatch_block_t block = ^{
		@autoreleasepool {
			__block NSArray *objects	= nil;
			__block BOOL success		= NO;
			
			dispatch_sync(self.setQueue, ^{
				if (self.needsSave) {
					objects = self.contents.allObjects;
					success = YES;
					self.needsSave = NO;
				}
			});
			
			// Prevent overwork
			if (!success) {
				return;
			}
			
			// At last: save!
			if (![[objects sp_JSONData] writeToURL:self.mutableSetURL atomically:NO]) {
				SPLogError(@"<> %@ :: Error while performing a save operation", NSStringFromClass([self class]));
			}
		};
	};
	
	if (wait) {
		dispatch_sync(self.saveQueue, block);
	} else {
		dispatch_async(self.saveQueue, block);
	}
}

+ (instancetype)loadSetWithLabel:(NSString *)label {
	SPPersistentMutableSet *loaded = [[SPPersistentMutableSet alloc] initWithLabel:label];
		
	[loaded migrateIfNeeded];
	[loaded loadFromFilesystem];
		
	return loaded;
}


#pragma mark ====================================================================================
#pragma mark Helpers
#pragma mark ====================================================================================

- (void)loadFromFilesystem {
	NSData *rawData	= [NSData dataWithContentsOfURL:self.mutableSetURL];
	NSArray *list	= [rawData sp_objectFromJSONString];
    if (list.count > 0) {
        [self addObjectsFromArray:list];
	}
}

// NOTE: This helper class used to rely on NSUserDefaults. Due to performance issues, we've moved to the filesystem!
- (void)migrateIfNeeded {
	
	// Load + Import
	NSArray *list = [[[NSUserDefaults standardUserDefaults] objectForKey:self.label] sp_objectFromJSONString];
	
    if (list.count == 0) {
		return;
	}
	
	[self addObjectsFromArray:list];
	[self save];
	
	// Nuke defaults
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:self.label];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSURL *)mutableSetURL {
	
	if (_mutableSetURL) {
		return _mutableSetURL;
	}
	
	@synchronized(self) {
		// If the baseURL doesn't exist, create it
		NSURL *baseURL	= self.baseURL;
		
		NSError *error	= nil;
		BOOL success	= [[NSFileManager defaultManager] createDirectoryAtURL:baseURL withIntermediateDirectories:YES attributes:nil error:&error];
		
		if (!success) {
			SPLogError(@"%@ could not create baseURL %@ :: %@", NSStringFromClass([self class]), baseURL, error);
			abort();
		}
		
		_mutableSetURL = [baseURL URLByAppendingPathComponent:self.filename];
	}
	
	return _mutableSetURL;
}

- (NSString *)filename {
	return [NSString stringWithFormat:@"SPMutableSet-%@.dat", self.label];
}

#if TARGET_OS_IPHONE

- (NSURL *)baseURL {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
}

#else

- (NSURL *)baseURL {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	
	// NOTE:
	// While running UnitTests on OSX, the applicationSupport folder won't bear any application name.
	// This will cause, as a side effect, SPDictionaryStorage test-database's to get spread in the AppSupport folder.
	// As a workaround (until we figure out a better way of handling this), let's detect XCTestCase class, and append the Simperium-OSX name to the path.
	// That will generate an URL like this:
	//		- //Users/[USER]/Library/Application Support/Simperium-OSX/SPPersistentMutableSet/
	//
	if (NSClassFromString(@"XCTestCase") != nil) {
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		appSupportURL = [appSupportURL URLByAppendingPathComponent:[bundle objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]];
	}
	
	return [appSupportURL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

#endif

@end

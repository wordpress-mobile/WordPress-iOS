//
//  SPPersistentMutableDictionary.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 9/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPPersistentMutableDictionary.h"
#import <CoreData/CoreData.h>
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString *SPDictionaryEntityName		= @"SPDictionaryEntityName";
static NSString *SPDictionaryEntityValue	= @"value";
static NSString *SPDictionaryEntityKey		= @"key";

static SPLogLevels logLevel					= SPLogLevelsError;


#pragma mark ====================================================================================
#pragma mark Private Methods
#pragma mark ====================================================================================

@interface SPPersistentMutableDictionary ()
@property (nonatomic, strong, readwrite) NSString                       *label;
@property (nonatomic, strong, readwrite) NSCache                        *cache;
@property (nonatomic, strong, readwrite) NSManagedObjectContext         *managedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectModel           *managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator   *persistentStoreCoordinator;
- (NSURL*)baseURL;
@end


#pragma mark ====================================================================================
#pragma mark SPMutableDictionaryStorage
#pragma mark ====================================================================================

@implementation SPPersistentMutableDictionary

- (id)initWithLabel:(NSString *)label {
    self = [super init];
	if (self) {
		self.label = label;
		self.cache = [[NSCache alloc] init];
	}
	
	return self;
}

- (NSInteger)count {
	__block NSUInteger count = 0;
	
	[self.managedObjectContext performBlockAndWait:^() {
		NSError *error;
		count = [self.managedObjectContext countForFetchRequest:[self requestForEntity] error:&error];
		SPLogOnError(error);
	}];
	
	return count;
}

- (BOOL)containsObjectForKey:(id)aKey {
	if (aKey == nil) {
		return false;
	}
	
	// Do we have a cache hit?
	__block BOOL exists = ([self.cache objectForKey:aKey] != nil);
	if (exists) {
		return exists;
	}
	
	// Fault to Core Data
	[self.managedObjectContext performBlockAndWait:^{
		NSError *error = nil;
		exists = ([self.managedObjectContext countForFetchRequest:[self requestForEntityWithKey:aKey] error:&error] > 0);
		SPLogOnError(error);
	}];
	
	// Done
	return exists;
}

- (id)objectForKey:(id)aKey {
	if (aKey == nil) {
		return nil;
	}

	// Do we have a cache hit?
	__block id value = [self.cache objectForKey:aKey];
	if (value) {
		return value;
	}
	
	// Fault to Core Data
	[self.managedObjectContext performBlockAndWait:^{
		NSError *error = nil;
		NSArray *results = [self.managedObjectContext executeFetchRequest:[self requestForEntityWithKey:aKey] error:&error];
		SPLogOnError(error);

		if (results.count)
		{
			NSManagedObject *object = (NSManagedObject*)[results firstObject];
			
			// Unarchive
			id archivedValue = [object valueForKey:SPDictionaryEntityValue];
			if (archivedValue) {
				value = [NSKeyedUnarchiver unarchiveObjectWithData:archivedValue];
			}
		}
	}];
	
	// Cache
	if (value) {
		[self.cache setObject:value forKey:aKey];
	}
	
	// Done
	return value;
}

- (void)setObject:(id)anObject forKey:(NSString*)aKey {
	if (anObject == nil) {
		[self removeObjectForKey:aKey];
		return;
	}

	[self.managedObjectContext performBlock:^{
		
		NSError *error = nil;
		NSArray *results = [self.managedObjectContext executeFetchRequest:[self requestForEntityWithKey:aKey] error:&error];
		NSAssert(results.count <= 1, @"ERROR: SPMetadataStorage has multiple entities with the same key");
		SPLogOnError(error);
				
		// Upsert
		NSManagedObject *change;
		if (results.count) {
			change = (NSManagedObject*)results[0];
		} else {
			change = [NSEntityDescription insertNewObjectForEntityForName:SPDictionaryEntityName inManagedObjectContext:self.managedObjectContext];
			[change setValue:aKey forKey:SPDictionaryEntityKey];
		}
		
		// Wrap up the value
		id archivedValue = [NSKeyedArchiver archivedDataWithRootObject:anObject];
		[change setValue:archivedValue forKey:SPDictionaryEntityValue];
	}];
	
	// Update the cache
	[self.cache setObject:anObject forKey:aKey];
}

- (BOOL)save {
	__block BOOL success = NO;
	
	[self.managedObjectContext performBlockAndWait:^{
		
		NSError *error = nil;
		success = [self.managedObjectContext save:&error];
		SPLogOnError(error);
	}];
	
	return success;
}

- (NSArray*)allKeys {
	return [self loadObjectsProperty:SPDictionaryEntityKey unarchive:NO];
}

- (NSArray*)allValues {
	return [self loadObjectsProperty:SPDictionaryEntityValue unarchive:YES];
}

- (void)removeObjectForKey:(id)aKey {
	if (aKey == nil) {
		return;
	}
	
	[self.managedObjectContext performBlock:^{
		
		// Load the objectID
		NSFetchRequest *request = [self requestForEntityWithKey:aKey];
		[request setIncludesPropertyValues:NO];
		
		NSError *error = nil;
		NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
		SPLogOnError(error);
		
		// Once there, delete
		if (results.count) {
			NSManagedObject *object = (NSManagedObject*)[results firstObject];
			[self.managedObjectContext deleteObject:object];
		}
	}];
	
	// Persist & Update the cache
	[self.cache removeObjectForKey:aKey];
}

- (void)removeAllObjects {
	[self.managedObjectContext performBlock:^{
		
		// Fetch the objectID's
		NSFetchRequest *fetchRequest = [self requestForEntity];
		[fetchRequest setIncludesPropertyValues:NO];

		NSError *error = nil;
		NSArray *allObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		SPLogOnError(error);
		
		// Delete Everything
		for (NSManagedObject *object in allObjects) {
			[self.managedObjectContext deleteObject:object];
		}
	}];
	
	// Persist & Update the cache
	[self.cache removeAllObjects];
}


+ (instancetype)loadDictionaryWithLabel:(NSString *)label {
	return [[SPPersistentMutableDictionary alloc] initWithLabel:label];
}

#pragma mark ====================================================================================
#pragma mark Core Data Stack
#pragma mark ====================================================================================

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }

	@synchronized(self) {
        if (_managedObjectModel) {
            return _managedObjectModel;
        }
        
        // Dynamic Attributes
        NSAttributeDescription *keyAttribute    = [[NSAttributeDescription alloc] init];
        keyAttribute.name                       = @"key";
        keyAttribute.attributeType              = NSStringAttributeType;
        keyAttribute.optional                   = NO;
        keyAttribute.indexed                    = YES;
        
        NSAttributeDescription *valueAttribute  = [[NSAttributeDescription alloc] init];
        valueAttribute.name                     = @"value";
        valueAttribute.attributeType            = NSBinaryDataAttributeType;
        valueAttribute.optional                 = NO;
        
        // SPMetadata Entity
        NSEntityDescription *entity             = [[NSEntityDescription alloc] init];
        entity.name                             = SPDictionaryEntityName;
        entity.managedObjectClassName           = NSStringFromClass([NSManagedObject class]);
        entity.properties                       = @[keyAttribute, valueAttribute];
        
        // Done!
        NSManagedObjectModel *model             = [[NSManagedObjectModel alloc] init];
        model.entities                          = @[entity];
        
        _managedObjectModel = model;
    }
	
	return _managedObjectModel;
}

- (NSManagedObjectContext*)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
	
    @synchronized(self) {
        if (_managedObjectContext) {
            return _managedObjectContext;
        }
        
        NSManagedObjectContext *managedObjectContext    = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        _managedObjectContext                           = managedObjectContext;
    }
    
    return _managedObjectContext;
}


- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
	@synchronized(self) {
        if (_persistentStoreCoordinator) {
            return _persistentStoreCoordinator;
        }
        
		NSURL *baseURL	= [self baseURL];
		
		NSError *error	= nil;
		BOOL success	= [[NSFileManager defaultManager] createDirectoryAtURL:baseURL withIntermediateDirectories:YES attributes:nil error:&error];
		
		if (!success) {
			SPLogError(@"%@ could not create baseURL %@", NSStringFromClass([self class]), baseURL);
			abort();
		}
		
		// We've moved the store location to NSApplicationSupportDirectory. Let's move old folders, if needed
		[self migrateIfNeeded];
		
		// Finally, load the PSC
		NSURL *storeURL = [baseURL URLByAppendingPathComponent:self.filename];
		
        NSManagedObjectModel *context       = self.managedObjectModel;
		NSPersistentStoreCoordinator *psc   = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:context];
		if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
		{
			SPLogError(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
        
        _persistentStoreCoordinator = psc;
	}
    
    return _persistentStoreCoordinator;
}


#pragma mark ====================================================================================
#pragma mark Helpers
#pragma mark ====================================================================================

- (NSString *)filename {
	return [NSString stringWithFormat:@"SPDictionary-%@.sqlite", self.label];
}

#if TARGET_OS_IPHONE

- (NSURL *)baseURL {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)migrateIfNeeded {

	NSFileManager *fileManager	= [NSFileManager defaultManager];
	NSURL *oldBaseURL			= [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *newBaseURL			= self.baseURL;
	NSArray *contents			= [fileManager contentsOfDirectoryAtURL:oldBaseURL includingPropertiesForKeys:@[NSURLNameKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants error:nil];
	NSString *filename			= self.filename;
	
	// CoreData usually generates three files per PSC. Let's move all of them
	for (NSURL *oldFileURL in contents) {
		if ([oldFileURL.lastPathComponent hasPrefix:filename] == NO) {
			continue;
		}
		
		NSError *error		= nil;
		NSURL *newFileURL	= [newBaseURL URLByAppendingPathComponent:oldFileURL.lastPathComponent];
		
		if ( ![fileManager moveItemAtURL:oldFileURL toURL:newFileURL error:&error] ) {
			SPLogError(@"Error migrating %@ from %@ to %@", NSStringFromClass([self class]), oldFileURL, newFileURL);
		}
	}
}

#else

- (NSURL *)baseURL {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	
	// NOTE:
	// While running UnitTests on OSX, the applicationSupport folder won't bear any application name.
	// This will cause, as a side effect, SPDictionaryStorage test-database's to get spread in the AppSupport folder.
	// As a workaround (until we figure out a better way of handling this), let's detect XCTestCase class, and append the Simperium-OSX name to the path.
	// That will generate an URL like this:
	//		- //Users/[USER]/Library/Application Support/Simperium-OSX/SPDictionaryStorage/
	//
	if (NSClassFromString(@"XCTestCase") != nil) {
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		appSupportURL = [appSupportURL URLByAppendingPathComponent:[bundle objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]];
	}
		
	return [appSupportURL URLByAppendingPathComponent:NSStringFromClass([self class])];
}

- (void)migrateIfNeeded {
	// No-Op. We're already in the right location
}


#endif

- (NSFetchRequest *)requestForEntity {
	return [NSFetchRequest fetchRequestWithEntityName:SPDictionaryEntityName];
}

- (NSFetchRequest *)requestForEntityWithKey:(id)aKey {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:SPDictionaryEntityName];
	request.predicate       = [NSPredicate predicateWithFormat:@"key == %@", aKey];
	request.fetchLimit      = 1;
	
	return request;
}

- (NSArray *)loadObjectsProperty:(NSString*)property unarchive:(BOOL)unarchive {
	NSMutableArray *keys = [NSMutableArray array];
	
	[self.managedObjectContext performBlockAndWait:^{
		
		// Fetch the objects
		NSError *error = nil;
		NSArray *allObjects = [self.managedObjectContext executeFetchRequest:[self requestForEntity] error:&error];
		SPLogOnError(error);
		
		// Load properties
		for (NSManagedObject *change in allObjects) {
			id value = [change valueForKey:property];
			if (!value) {
				continue;
			}
			
			if (unarchive) {
				[keys addObject:[NSKeyedUnarchiver unarchiveObjectWithData:value]];
			} else {
				[keys addObject:value];
			}
		}
	}];
	
	return keys;
}

@end

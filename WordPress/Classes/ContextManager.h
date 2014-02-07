/*
 * ContextManager.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@interface ContextManager : NSObject

///----------------------------------------------
///@name Persistent Contexts
///
/// The backgroundContext has concurrency type
/// NSPrivateQueueConcurrencyType and should be
/// used for any background tasks. Its parent is
/// the persistentStoreCoordinator.
///
/// The mainContext has concurrency type
/// NSMainQueueConcurrencyType and should be used
/// for UI elements and fetched results controllers.
/// During Simperium startup, a backgroundWriterContext
///  will be created.
///----------------------------------------------
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;

///-------------------------------------------------------------
///@name Access to the persistent store and managed object model
///-------------------------------------------------------------
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;

///--------------------------------------
///@name ContextManager
///--------------------------------------

/**
 Returns the singleton
 
 @return instance of ContextManager
*/
+ (instancetype)sharedInstance;


///--------------------------
///@name Contexts
///--------------------------

/**
 For usage as a 'scratch pad' context
 
 @return a new MOC with NSPrivateQueueConcurrencyType, 
 with the parent context as the main context
*/
- (NSManagedObjectContext *const)newDerivedContext;

/**
 Save a derived context created with `newDerivedContext` via this convenience method
 
 @param a derived NSManagedObjectContext constructed with `newDerivedContext` above
*/
- (void)saveDerivedContext:(NSManagedObjectContext *)context;

/**
 Save a derived context created with `newDerivedContext` and optionally execute a completion block.
 Useful for if the guarantee is needed that the data has made it into the main context.
 
 @param a derived NSManagedObjectContext constructed with `newDerivedContext` above
 @param a completion block that will be executed on the main queue
 */
- (void)saveDerivedContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock;

/**
 Save a given context.
 
 Convenience for error handling.
 */
- (void)saveContext:(NSManagedObjectContext *)context;


/**
 Save a given context.
 
 @param a NSManagedObject context instance
 @param a completion block that will be executed on the main queue
 */
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock;

@end

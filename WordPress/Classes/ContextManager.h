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
/// Its parent is the backgroundContext.
///----------------------------------------------
@property (nonatomic, readonly, strong) NSManagedObjectContext *backgroundContext;
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
 with the parent context as the background writer context
*/
- (NSManagedObjectContext *const)newDerivedContext;

/**
 Save a context via this convenience method
*/
- (void)saveDerivedContext:(NSManagedObjectContext *)context;

@end

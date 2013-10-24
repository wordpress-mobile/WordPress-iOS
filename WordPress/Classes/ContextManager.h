//
//  ContextManager.h
//  WordPress
//
//  Created by DX074-XL on 2013-10-18.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContextManager : NSObject

+ (instancetype)sharedInstance;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectContext *const)newDerivedContext;
- (NSManagedObjectContext *const)mainContext;

- (void)saveMainContext;
- (void)saveWithContext:(NSManagedObjectContext *)context;

- (NSFetchRequest *)fetchRequestTemplateForName:(NSString *)templateName;

@end

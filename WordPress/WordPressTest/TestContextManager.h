//
//  TestContextManager.h
//  WordPress
//
//  Created by Aaron Douglas on 10/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "ContextManager.h"

@interface TestContextManager : ContextManager

@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@end

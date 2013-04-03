//
//  ReaderContext.h
//  WordPress
//
//  Created by Eric J on 3/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReaderContext : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (ReaderContext *)sharedReaderContext;

@end

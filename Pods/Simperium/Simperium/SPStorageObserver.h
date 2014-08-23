//
//  SPStorageObserver.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

@protocol SPStorageObserver <NSObject>
- (BOOL)objectsShouldSync;
- (void)storage:(SPStorage *)storage updatedObjects:(NSSet *)updatedObjects insertedObjects:(NSSet *)insertedObjects deletedObjects:(NSSet *)deletedObjects;
@end

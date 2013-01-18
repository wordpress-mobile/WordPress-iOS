//
//  FakeMigration.m
//  WordPress
//
//  Created by Jorge Bernal on 2/21/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FakeMigration.h"


@implementation FakeMigration
- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)performCustomValidationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)source 
                                      entityMapping:(NSEntityMapping *)mapping 
                                            manager:(NSMigrationManager *)manager 
                                              error:(NSError **)error
{
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)source 
                                    entityMapping:(NSEntityMapping*)mapping 
                                          manager:(NSMigrationManager*)manager 
                                            error:(NSError**)error
{
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}


@end

//
//  FakeMigration.m
//  WordPress
//
//  Created by Jorge Bernal on 2/21/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FakeMigration.h"


@implementation FakeMigration
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)source 
                                      entityMapping:(NSEntityMapping *)mapping 
                                            manager:(NSMigrationManager *)manager 
                                              error:(NSError **)error
{
    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)source 
                                    entityMapping:(NSEntityMapping*)mapping 
                                          manager:(NSMigrationManager*)manager 
                                            error:(NSError**)error
{
    return YES;
}


@end

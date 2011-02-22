//
//  MigrateBlogsFromFiles.m
//  WordPress
//
//  Created by Jorge Bernal on 2/14/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "MigrateBlogsFromFiles.h"


@implementation MigrateBlogsFromFiles

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	WPLog(@"beginEntityMapping");
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
    NSString *blogsArchiveFilePath = [currentDirectoryPath stringByAppendingPathComponent:@"blogs.archive"];
	
    if ([fileManager fileExistsAtPath:blogsArchiveFilePath]) {
        // set method will release, make mutable copy and retain
        NSArray *blogs = [NSKeyedUnarchiver unarchiveObjectWithFile:blogsArchiveFilePath];
		WPLog(@"Got blogs list from 2.6: %i blogs", [blogs count]);
		
		NSManagedObjectContext *destMOC = [manager destinationContext];
		NSError *error = nil;

		for (NSDictionary *blogInfo in blogs) {
			NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog"
																  inManagedObjectContext:destMOC];
			[blog setValue:[[blogInfo valueForKey:@"blogid"] numericValue] forKey:@"blogID"];
			[blog setValue:[blogInfo valueForKey:@"blogName"] forKey:@"blogName"];
			NSString *blogUrl = [blogInfo valueForKey:@"url"];
			blogUrl = [blogUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
			if([blogUrl hasSuffix:@"/"])
				blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
			blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			[blog setValue:blogUrl forKey:@"url"];
			[blog setValue:[blogInfo valueForKey:@"username"] forKey:@"username"];
			[blog setValue:[blogInfo valueForKey:@"xmlrpc"] forKey:@"xmlrpc"];
			[blog setValue:[NSNumber numberWithBool:YES] forKey:@"isAdmin"];
			if ([[blogInfo valueForKey:@"GeolocationSetting"] isKindOfClass:[NSString class]]) {
				BOOL geo = [[blogInfo valueForKey:@"GeolocationSetting"] isEqualToString:@"YES"];
				[blog setValue:[NSNumber numberWithBool:geo] forKey:@"geolocationEnabled"];
			} else {
				[blog setValue:[blogInfo valueForKey:@"GeolocationSetting"] forKey:@"geolocationEnabled"];
			}
			if ([blog validateForInsert:&error]) {
				WPLog(@"* Migrated blog %@", [blog valueForKey:@"blogName"]);
			} else {
				WPLog(@"! Failed migration for blog %@: %@", [blog valueForKey:@"blogName"], [error localizedDescription]);
			}

			
			// Import categories
			NSArray *categories = [blogInfo valueForKey:@"categories"];
			for (NSDictionary *categoryInfo in categories) {
				NSManagedObject *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
																		  inManagedObjectContext:destMOC];
				[category setValue:blog forKey:@"blog"];
				[category setValue:[[categoryInfo valueForKey:@"categoryId"] numericValue] forKey:@"categoryID"];
				[category setValue:[categoryInfo valueForKey:@"categoryName"] forKey:@"categoryName"];
				[category setValue:[[categoryInfo valueForKey:@"parentId"] numericValue] forKey:@"parentID"];

				if ([category validateForInsert:&error]) {
					WPLog(@"** Migrated category %@ in blog %@", [category valueForKey:@"categoryName"], [blog valueForKey:@"blogName"]);
				} else {
					WPLog(@"!! Failed migration for category %@ in blog %@: %@", [category valueForKey:@"categoryName"], [blog valueForKey:@"blogName"], [error localizedDescription]);
				}
			}
		}
	}
	return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)performCustomValidationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)source 
                                      entityMapping:(NSEntityMapping *)mapping 
                                            manager:(NSMigrationManager *)manager 
                                              error:(NSError **)error
{		
	WPLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)source 
                                    entityMapping:(NSEntityMapping*)mapping 
                                          manager:(NSMigrationManager*)manager 
                                            error:(NSError**)error
{
	WPLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
    return YES;
}

@end

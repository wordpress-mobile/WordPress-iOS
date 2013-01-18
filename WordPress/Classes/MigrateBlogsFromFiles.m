//
//  MigrateBlogsFromFiles.m
//  WordPress
//
//  Created by Jorge Bernal on 2/14/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "MigrateBlogsFromFiles.h"


@implementation MigrateBlogsFromFiles

- (BOOL)forceBlogsMigrationInContext:(NSManagedObjectContext *)destMOC error:(NSError **)error {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
    NSString *blogsArchiveFilePath = [currentDirectoryPath stringByAppendingPathComponent:@"blogs.archive"];
	
    if ([fileManager fileExistsAtPath:blogsArchiveFilePath]) {
        // set method will release, make mutable copy and retain
        NSArray *blogs = [NSKeyedUnarchiver unarchiveObjectWithFile:blogsArchiveFilePath];
		WPFLog(@"Got blogs list from 2.6: %i blogs", [blogs count]);
		
		NSError *error = nil;
		
		for (NSDictionary *blogInfo in blogs) {
			NSString *blogUrl = [blogInfo valueForKey:@"url"];
			blogUrl = [blogUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
			if([blogUrl hasSuffix:@"/"])
				blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
			blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
												inManagedObjectContext:destMOC]];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@ AND blogName == %@",
										blogUrl,
										[blogInfo valueForKey:@"blogName"]]];
			NSArray *results = [destMOC executeFetchRequest:fetchRequest error:&error];
			if (results && [results count] > 0) {
				// Don't duplicate blogs
				WPFLog(@"! Skipping already imported blog %@", [blogInfo valueForKey:@"blogName"]);
				continue;
			}
			
			NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog"
																  inManagedObjectContext:destMOC];
			[blog setValue:[[blogInfo valueForKey:@"blogid"] numericValue] forKey:@"blogID"];
			[blog setValue:[blogInfo valueForKey:@"blogName"] forKey:@"blogName"];			
			[blog setValue:blogUrl forKey:@"url"];
			[blog setValue:[blogInfo valueForKey:@"username"] forKey:@"username"];
			[blog setValue:[blogInfo valueForKey:@"xmlrpc"] forKey:@"xmlrpc"];
			[blog setValue:[NSNumber numberWithBool:YES] forKey:@"isAdmin"];
			if ([[blogInfo valueForKey:@"GeolocationSetting"] isKindOfClass:[NSString class]]) {
				BOOL geo = [[blogInfo valueForKey:@"GeolocationSetting"] isEqualToString:@"YES"];
				[blog setValue:[NSNumber numberWithBool:geo] forKey:@"geolocationEnabled"];
			} else {
				NSNumber *geo = [blogInfo valueForKey:@"GeolocationSetting"];
				if (geo == nil || ![geo isKindOfClass:[NSNumber class]]) {
					geo = [NSNumber numberWithBool:NO];
				}
				[blog setValue:geo forKey:@"geolocationEnabled"];
			}
			if ([blog validateForInsert:&error]) {
				WPFLog(@"* Migrated blog %@", [blog valueForKey:@"blogName"]);
			} else {
				WPFLog(@"! Failed migration for blog %@: %@", [blog valueForKey:@"blogName"], [error localizedDescription]);
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
					WPFLog(@"** Migrated category %@ in blog %@", [category valueForKey:@"categoryName"], [blog valueForKey:@"blogName"]);
				} else {
					WPFLog(@"!! Failed migration for category %@ in blog %@: %@", [category valueForKey:@"categoryName"], [blog valueForKey:@"blogName"], [error localizedDescription]);
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	WPFLog(@"beginEntityMapping");
	NSManagedObjectContext *destMOC = [manager destinationContext];

	return [self forceBlogsMigrationInContext:destMOC error:error];
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

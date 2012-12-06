//
//  PostToAbstractPost.m
//  WordPress
//
//  Created by Jorge Bernal on 2/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "PostToAbstractPost.h"
#import "AbstractPost.h"
#import "Media.h"

@implementation PostToAbstractPost

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
	if ([[source valueForKey:@"blogID"] isEqualToString:@"0"]) {
		WPFLog(@"! Ignoring post with blog id 0");
		return YES;
	}
	if ([[source valueForKey:@"isLocalDraft"] isEqual:[NSNumber numberWithBool:NO]]) {
		WPFLog(@"! Ignoring not local draft post");
		return YES;
	}
	if ([[source valueForKey:@"isAutosave"] isEqual:[NSNumber numberWithBool:YES]]) {
		WPFLog(@"! Ignoring autosave");
		return YES;
	}
	NSManagedObjectContext *destMOC = [manager destinationContext];
	NSManagedObject *apost;
	NSError *err = nil;
	NSString *postType = [source valueForKey:@"postType"];
	NSFetchRequest *fetchRequest;
	NSArray *results = nil;
	
	// Local drafts in 2.6 were only related to blogs by blogID, which is 1 in most wporg blogs
	// Let's find if the post has some media attached: media items have blogURL which can help
	fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media"
                                        inManagedObjectContext:[source managedObjectContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"postID == %@", [source valueForKey:@"postID"]]];
	NSArray *mediaItems = [[source managedObjectContext] executeFetchRequest:fetchRequest error:&err];
	if (mediaItems && [mediaItems count] > 0) {
		// We have attachments
		NSManagedObject *media = [mediaItems objectAtIndex:0];
		NSString *blogUrl = [media valueForKey:@"blogURL"];
		blogUrl = [blogUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
		if([blogUrl hasSuffix:@"/"])
			blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
		blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

		fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
											inManagedObjectContext:destMOC]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url like '*%@*'", blogUrl]];
		results = [destMOC executeFetchRequest:fetchRequest error:&err];
	}
	
	if (!results || [results count] == 0) {
		// No media, let's find every blog that matches blogID
		fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
											inManagedObjectContext:destMOC]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"blogID == %@", [[source valueForKey:@"blogID"] numericValue]]];
		results = [destMOC executeFetchRequest:fetchRequest error:&err];
	}
	
	WPFLog(@"* Initiating migration for %@", [source valueForKey:@"postTitle"]);	
	if (results && [results count] > 0) {
		for (NSManagedObject *blog in results) {
			if ([postType isEqualToString:@"page"]) {
				apost = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
													  inManagedObjectContext:destMOC];
			} else {
				apost = [NSEntityDescription insertNewObjectForEntityForName:@"Post"
													  inManagedObjectContext:destMOC];
				[apost setValue:[source valueForKey:@"tags"] forKey:@"tags"];
				NSString *categoriesText = [source valueForKey:@"categories"];
				if (categoriesText && ![categoriesText isEqualToString:@""]) {
					NSArray *categories = [categoriesText componentsSeparatedByString:@", "];
					NSMutableSet *postCategories = [apost mutableSetValueForKey:@"categories"];
					for (NSString *categoryName in categories) {
						NSMutableSet *blogCategories = [blog mutableSetValueForKey:@"categories"];
						NSSet *results = [blogCategories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName == %@", categoryName]];
						
						if (results && [results count] > 0) {
							[postCategories addObjectsFromArray:[results allObjects]];
							WPFLog(@"** Adding category %@ to post %@", categoryName, [source valueForKey:@"postTitle"]);
						} else {
							WPFLog(@"!! Category %@ not found for post %@ in blog %@", categoryName, [source valueForKey:@"postTitle"], [blog valueForKey:@"blogName"]);
						}

					}
					[apost setValue:postCategories forKey:@"categories"];
				}
			}
			[apost setValue:[source valueForKey:@"postTitle"] forKey:@"postTitle"];
			[apost setValue:[source valueForKey:@"content"] forKey:@"content"];
			[apost setValue:[NSNumber numberWithInt:AbstractPostRemoteStatusLocal] forKey:@"remoteStatusNumber"];
			[apost setValue:@"Draft" forKey:@"status"];
			
			[apost setValue:blog forKey:@"blog"];
			
			if (mediaItems && [mediaItems count] > 0) {
				for (NSManagedObject *media in mediaItems) {
					NSString *blogUrl = [media valueForKey:@"blogURL"];
					blogUrl = [blogUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
					if([blogUrl hasSuffix:@"/"])
						blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
					blogUrl = [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

					// If we good a good blog match we use that
					// If there are multiple blogs, and media's blogURL matches this one we add it too
					if (([results count] == 1) || (blogUrl && [[blog valueForKey:@"url"] rangeOfString:blogUrl].location != NSNotFound)) {
						NSManagedObject *newMedia = [NSEntityDescription insertNewObjectForEntityForName:@"Media"
																				  inManagedObjectContext:destMOC];
						[newMedia setValue:[NSMutableSet setWithObject:apost] forKey:@"posts"];
						[newMedia setValue:blog forKey:@"blog"];
						[newMedia setValue:[NSNumber numberWithInt:MediaRemoteStatusSync] forKey:@"remoteStatusNumber"];
						
						[newMedia setValue:[media valueForKey:@"mediaType"] forKey:@"mediaType"];
						[newMedia setValue:[media valueForKey:@"remoteURL"] forKey:@"remoteURL"];
						[newMedia setValue:[media valueForKey:@"localURL"] forKey:@"localURL"];
						[newMedia setValue:[media valueForKey:@"shortcode"] forKey:@"shortcode"];
						[newMedia setValue:[media valueForKey:@"width"] forKey:@"width"];
						[newMedia setValue:[media valueForKey:@"length"] forKey:@"length"];
						[newMedia setValue:[media valueForKey:@"title"] forKey:@"title"];
						[newMedia setValue:[media valueForKey:@"thumbnail"] forKey:@"thumbnail"];
						[newMedia setValue:[media valueForKey:@"height"] forKey:@"height"];
						[newMedia setValue:[media valueForKey:@"filename"] forKey:@"filename"];
						[newMedia setValue:[media valueForKey:@"filesize"] forKey:@"filesize"];
						[newMedia setValue:[media valueForKey:@"orientation"] forKey:@"orientation"];
						[newMedia setValue:[media valueForKey:@"creationDate"] forKey:@"creationDate"];
						
						if ([newMedia validateForInsert:&err]) {
							WPFLog(@"** Migrated media %@ for post %@ in blog %@",
								  [newMedia valueForKey:@"filename"],
								  [apost valueForKey:@"postTitle"],
								  [blog valueForKey:@"blogName"]);
						} else {
							WPFLog(@"!! Failed migrating media %@ for post %@ in blog %@",
								  [newMedia valueForKey:@"filename"],
								  [apost valueForKey:@"postTitle"],
								  [blog valueForKey:@"blogName"]);
							if (error) {
								*error = err;
							}
							return NO;
						}

					}
				}
				// See #1510: Import media items here
				WPFLog(@"* See trac #1510: import media items");
			}
			if ([apost validateForInsert:&err]) {
				WPFLog(@"* Migrated post %@ for blog %@", [apost valueForKey:@"postTitle"], [blog valueForKey:@"blogName"]);
				[manager associateSourceInstance:source
						 withDestinationInstance:apost
								forEntityMapping:mapping];
			} else {
				WPFLog(@"! Failed migrating post %@ for blog %@: %@", [apost valueForKey:@"postTitle"], [blog valueForKey:@"blogName"], [err localizedDescription]);
				if (error) {
					*error = err;
				}
				return NO;
			}			
		}
	} else {
		WPFLog(@"! Failed migrating post %@: %@", [source valueForKey:@"postTitle"], [err localizedDescription]);
		WPFLog(@"No blog found with id %@", [source valueForKey:@"blogID"]);
		if (error) {
			*error = err;
		}
		return NO;
	}

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

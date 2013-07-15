//
//  BlogToJetpackAccount.m
//  WordPress
//
//  Created by Jorge Bernal on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BlogToJetpackAccount.h"
#import "SFHFKeychainUtils.h"

static NSString * const BlogJetpackKeychainPrefix = @"jetpackblog-";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";

@implementation BlogToJetpackAccount

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

	NSManagedObjectContext *destMOC = [manager destinationContext];
    BOOL isWpcom = [self blogIsWpcom:source];
    if (isWpcom) {
        return YES;
    }
    NSString *xmlrpc = DotcomXmlrpcKey;
    NSString *username = [self jetpackUsernameForBlog:source];
    if (!username) {
        return YES;
    }
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@ and username = %@", DotcomXmlrpcKey, username]];
    NSArray *results = [destMOC executeFetchRequest:request error:nil];
    NSManagedObject *dest = [results lastObject];
    if (!dest) {
        dest = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:destMOC];
        [dest setValue:xmlrpc forKey:@"xmlrpc"];
        [dest setValue:username forKey:@"username"];
        [dest setValue:@YES forKey:@"isWpcom"];

        // Migrate passwords
        NSError *error;
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
        if (password) {
            if ([SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:DotcomXmlrpcKey updateExisting:YES error:&error]) {
                [SFHFKeychainUtils deleteItemForUsername:username andServiceName:@"WordPress.com" error:&error];
            }
        }
        if (error) {
            WPFLog(@"Error migrating password: %@", error);
        }
    }

    [manager associateSourceInstance:source withDestinationInstance:dest forEntityMapping:mapping];

    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)source
                                    entityMapping:(NSEntityMapping*)mapping
                                          manager:(NSMigrationManager*)manager
                                            error:(NSError**)error
{
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);

    NSArray *sourceBlogs = [manager sourceInstancesForEntityMappingNamed:@"BlogToJetpackAccount" destinationInstances:@[source]];
    NSArray *destBlogs = [manager destinationInstancesForEntityMappingNamed:@"BlogToBlog" sourceInstances:sourceBlogs];
    NSLog(@"dest blogs: %@", destBlogs);
    [source setValue:[NSSet setWithArray:destBlogs] forKey:@"jetpackBlogs"];

    return YES;
}

#pragma mark - Helpers

- (BOOL)blogIsWpcom:(NSManagedObject *)blog {
    NSDictionary *options = [blog valueForKey:@"options"];
    if (options && [options count] > 0) {
        NSDictionary *option = [options dictionaryForKey:@"wordpress.com"];
        if ([[option numberForKey:@"value"] boolValue]) {
            return YES;
        }
    }
    NSRange range = [[blog valueForKey:@"xmlrpc"] rangeOfString:@"wordpress.com"];
	return (range.location != NSNotFound);
}

- (NSString *)jetpackDefaultsKeyForBlog:(NSManagedObject *)blog {
    return [NSString stringWithFormat:@"%@%@", BlogJetpackKeychainPrefix, [blog valueForKey:@"url"]];
}

- (NSString *)jetpackUsernameForBlog:(NSManagedObject *)blog {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self jetpackDefaultsKeyForBlog:blog]];
}

- (NSString *)jetpackPasswordForBlog:(NSManagedObject *)blog {
    NSError *error = nil;
    return [SFHFKeychainUtils getPasswordForUsername:[self jetpackUsernameForBlog:blog] andServiceName:@"WordPress.com" error:&error];
}

@end

//
//  BlogToAccount.m
//  WordPress
//
//  Created by Jorge Bernal on 4/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BlogToAccount.h"
#import <NSURL+IDN.h>
#import "SFHFKeychainUtils.h"

static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";

@implementation BlogToAccount {
    NSString *_defaultWpcomUsername;
}

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);
	return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	WPFLog(@"%@ %@ (%@ -> %@)", self, NSStringFromSelector(_cmd), [mapping sourceEntityName], [mapping destinationEntityName]);

    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    if (!username) {
        // There is no default WordPress.com account, nothing to do here
        return YES;
    }

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@ AND username = %@", DotcomXmlrpcKey, username]];
    NSManagedObjectContext *destMOC = [manager destinationContext];
    NSArray *results = [destMOC executeFetchRequest:request error:nil];
    NSManagedObject *account = [results lastObject];
    if (!account) {
        /*
         The default wp.com account (used for Reader/Notifications) doesn't have any blogs added in the app, so it wasn't created on the migration.
         */
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:destMOC];
        [account setValue:DotcomXmlrpcKey forKey:@"xmlrpc"];
        [account setValue:username forKey:@"username"];
        [account setValue:@YES forKey:@"isWpcom"];
        NSString *oldKey = @"WordPress.com";
        NSString *newKey = DotcomXmlrpcKey;

        NSError *error;
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:oldKey error:&error];
        if (password) {
            if ([SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:newKey updateExisting:YES error:&error]) {
                [SFHFKeychainUtils deleteItemForUsername:username andServiceName:oldKey error:&error];
            }
        }
        if (error) {
            WPFLog(@"Error migrating password: %@", error);
        }
    }

    NSURL *accountURL = [[account objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

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
    NSString *xmlrpc = [source valueForKey:@"xmlrpc"];
    if (isWpcom) {
        xmlrpc = DotcomXmlrpcKey;
    }
    NSString *username = [source valueForKey:@"username"];

    NSMutableDictionary *userInfo = (NSMutableDictionary*)[manager userInfo];
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
        [manager setUserInfo:userInfo];
    }
    NSMutableDictionary *accountLookup = [userInfo valueForKey:@"accounts"];
    if (!accountLookup) {
        accountLookup = [NSMutableDictionary dictionary];
        [userInfo setValue:accountLookup forKey:@"accounts"];
    }
    NSString *lookupKey = [NSString stringWithFormat:@"%@@%@", username, xmlrpc];
    NSManagedObject *dest = [accountLookup objectForKey:lookupKey];
    if (!dest) {
        dest = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:destMOC];
        [dest setValue:xmlrpc forKey:@"xmlrpc"];
        [dest setValue:username forKey:@"username"];
        [dest setValue:@(isWpcom) forKey:@"isWpcom"];
        [accountLookup setValue:dest forKey:lookupKey];

        // Migrate passwords
        NSString *oldKey;
        NSString *newKey;
        if (isWpcom) {
            oldKey = @"WordPress.com";
            newKey = DotcomXmlrpcKey;
        } else {
            oldKey = [self hostUrlForBlog:source];
            newKey = xmlrpc;
        }
        NSError *error;
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:oldKey error:&error];
        if (password) {
            if ([SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:newKey updateExisting:YES error:&error]) {
                [SFHFKeychainUtils deleteItemForUsername:username andServiceName:oldKey error:&error];
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

    NSArray *sourceBlogs = [manager sourceInstancesForEntityMappingNamed:@"BlogToAccount" destinationInstances:@[source]];
    NSArray *destBlogs = [manager destinationInstancesForEntityMappingNamed:@"BlogToBlog" sourceInstances:sourceBlogs];
    NSLog(@"dest blogs: %@", destBlogs);
    [source setValue:[NSSet setWithArray:destBlogs] forKey:@"blogs"];

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

- (NSString *)hostUrlForBlog:(NSManagedObject *)blog {
    NSString *url = [blog valueForKey:@"url"];
    NSError *error = NULL;
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"http(s?)://" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [NSString stringWithFormat:@"%@", [protocol stringByReplacingMatchesInString:[NSURL IDNDecodedHostname:url] options:0 range:NSMakeRange(0, [[NSURL IDNDecodedHostname:url] length]) withTemplate:@""]];

    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];

    return result;
}


@end

//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>

@interface Blog : NSManagedObject {
}

@property (nonatomic, retain) NSNumber *blogID;
@property (nonatomic, retain) NSString *blogName, *url, *username, *password, *xmlrpc;
@property (readonly) NSString *hostURL;
@property (nonatomic, assign) NSNumber *isAdmin;

- (UIImage *)favicon;
- (void)downloadFavicon;
- (void)downloadFaviconInBackground;
- (BOOL)isWPcom;
+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc;
+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc;

@end

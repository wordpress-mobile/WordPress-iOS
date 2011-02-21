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
@property (nonatomic, retain) NSString *blogName, *url, *username, *password, *xmlrpc, *apiKey;
@property (readonly) NSString *hostURL;
@property (nonatomic, assign) NSNumber *isAdmin, *hasOlderPosts, *hasOlderPages;
@property (nonatomic, retain) NSSet *posts;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, assign) BOOL isSyncingPosts;
@property (nonatomic, assign) BOOL isSyncingPages;
@property (nonatomic, assign) BOOL isSyncingComments;
@property (nonatomic, retain) NSDate *lastPostsSync;
@property (nonatomic, retain) NSDate *lastPagesSync;
@property (nonatomic, retain) NSDate *lastCommentsSync;
@property (nonatomic, retain) NSDate *lastStatsSync;
@property (nonatomic, assign) BOOL geolocationEnabled;

- (UIImage *)favicon;
- (void)downloadFavicon;
- (BOOL)isWPcom;
- (void)dataSave;

#pragma mark -
#pragma mark Synchronization
- (NSArray *)syncedPosts;
- (BOOL)syncPostsWithError:(NSError **)error loadMore:(BOOL)more;
- (BOOL)syncPagesWithError:(NSError **)error loadMore:(BOOL)more;
- (BOOL)syncCategoriesWithError:(NSError **)error;
- (BOOL)syncCommentsWithError:(NSError **)error;

#pragma mark -
#pragma mark Class methods
+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc;
+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc;
+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc;

@end

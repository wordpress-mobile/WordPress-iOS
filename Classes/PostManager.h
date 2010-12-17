//
//  PostManager.h
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "WPReachability.h"
#import "HttpHelper.h"
#import "XMLRPCConnection+Authentication.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "Post.h"

#define kLocalDraftKey @"local-draft"

@interface PostManager : NSObject {
	WordPressAppDelegate *appDelegate;
	BlogDataManager *dm;
	NSURL *xmlrpcURL;
	NSURLConnection *connection;
	NSURLRequest *urlRequest;
	NSURLResponse *urlResponse;
	NSMutableData *payload;
	NSMutableArray *posts, *postIDs;
	NSMutableDictionary *statuses;
	NSString *saveKey, *statusKey;
	
	BOOL isGettingPosts;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSURL *xmlrpcURL;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *payload;
@property (nonatomic, retain) NSMutableArray *posts, *postIDs;
@property (nonatomic, retain) NSMutableDictionary *statuses;
@property (nonatomic, retain) NSString *saveKey, *statusKey;
@property (nonatomic, assign) BOOL isGettingPosts;

- (void)initObjects;
- (id)initWithXMLRPCUrl:(NSString *)xmlrpc;
- (void)loadData;
- (void)loadStatuses;
- (void)storeData;
- (NSDictionary *)downloadPost:(NSNumber *)postID;
- (void)syncPosts;
- (void)syncPost:(NSNumber *)postID;
- (void)didSyncPosts;
- (void)syncStatuses;
- (void)syncStatusesInBackground;
- (NSDictionary *)getPost:(NSNumber *)postID;
- (void)addPost:(NSDictionary *)post;
- (void)getPosts;
- (void)getPostsInBackground;
- (void)didGetPosts;
- (BOOL)hasPostWithID:(NSNumber *)postID;
- (int)indexForPostID:(NSNumber *)postID;
- (id)executeXMLRPCRequest:(XMLRPCRequest *)xmlrpcRequest;
- (void)createPost:(Post *)post;
- (void)savePost:(Post *)post;
- (BOOL)deletePost:(NSNumber *)postID;
- (BOOL)verifyPublishSuccessful:(NSNumber *)postID localDraftID:(NSString *)uniqueID;

@end

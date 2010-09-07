//
//  PageManager.h
//  WordPress
//
//  Created by Chris Boyd on 9/6/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "HttpHelper.h"
#import "XMLRPCConnection+Authentication.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "Post.h"

#define kLocalDraftKey @"local-draft"

@interface PageManager : NSObject {
	WordPressAppDelegate *appDelegate;
	BlogDataManager *dm;
	NSURL *xmlrpcURL;
	NSURLConnection *connection;
	NSURLRequest *urlRequest;
	NSURLResponse *urlResponse;
	NSMutableData *payload;
	NSMutableArray *pages, *pageIDs;
	NSMutableDictionary *statuses;
	NSString *saveKey;
	
	BOOL isGettingPages;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSURL *xmlrpcURL;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *payload;
@property (nonatomic, retain) NSMutableArray *pages, *pageIDs;
@property (nonatomic, retain) NSMutableDictionary *statuses;
@property (nonatomic, retain) NSString *saveKey;
@property (nonatomic, assign) BOOL isGettingPages;

- (id)initWithXMLRPCUrl:(NSString *)xmlrpc;
- (void)loadData;
- (void)storeData;
- (NSDictionary *)downloadPage:(NSNumber *)pageID;
- (void)syncPages;
- (void)syncPage:(NSNumber *)pageID;
- (void)didSyncPages;
- (void)syncStatuses;
- (void)syncStatusesInBackground;
- (NSDictionary *)getPage:(NSNumber *)pageID;
- (void)addPage:(NSDictionary *)page;
- (void)getPages;
- (void)getPagesInBackground;
- (void)didGetPages;
- (BOOL)hasPageWithID:(NSNumber *)pageID;
- (int)indexForPageID:(NSNumber *)pageID;
- (id)executeXMLRPCRequest:(XMLRPCRequest *)xmlrpcRequest;
- (void)createPage:(Post *)page;
- (void)savePage:(Post *)page;
- (BOOL)deletePage:(NSNumber *)pageID;
- (BOOL)verifyPublishSuccessful:(NSNumber *)pageID localDraftID:(NSString *)uniqueID;

@end

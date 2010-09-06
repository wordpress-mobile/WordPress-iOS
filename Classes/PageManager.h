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
	NSMutableArray *pages;
	NSMutableDictionary *statuses;
	NSString *saveKey;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSURL *xmlrpcURL;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *payload;
@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSMutableDictionary *statuses;
@property (nonatomic, retain) NSString *saveKey;

- (id)initWithXMLRPCUrl:(NSString *)xmlrpc;
- (void)loadSavedPages;
- (void)syncPages;
- (void)didSyncPages;
- (void)syncStatuses;
- (NSDictionary *)getPage:(NSNumber *)pageID;
- (BOOL)hasPageWithID:(NSNumber *)pageID;
- (id)executeXMLRPCRequest:(XMLRPCRequest *)xmlrpcRequest;
- (void)createPage:(Post *)page;
- (void)savePage:(Post *)page;
- (BOOL)deletePage:(NSNumber *)pageID;
- (BOOL)verifyPublishSuccessful:(NSNumber *)pageID localDraftID:(NSString *)uniqueID;

@end

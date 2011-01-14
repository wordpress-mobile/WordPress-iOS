//
//  MediaManager.h
//  WordPress
//
//  Created by Chris Boyd on 8/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "Media.h"

@interface MediaManager : NSObject {
	WordPressAppDelegate *appDelegate;
}

- (Media *)get:(NSString *)uniqueID;
- (NSMutableArray *)getForPostID:(NSNumber *)postID andBlogURL:(NSString *)blogURL andMediaType:(MediaType)mediaType;
- (NSMutableArray *)getForBlogURL:(NSString *)blogURL andMediaType:(MediaType)mediaType;
- (BOOL)exists:(NSManagedObjectID *)uniqueID;
- (void)save:(Media *)media;
- (void)insert:(Media *)media;
- (void)update:(Media *)media;
- (void)remove:(Media *)media;
- (void)removeForBlogURL:(NSString *)blogURL;
- (void)removeForPostID:(NSNumber *)postID andBlogURL:(NSString *)blogURL;
- (void)dataSave;
- (void)doReport;

@end
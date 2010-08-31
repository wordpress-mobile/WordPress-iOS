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
- (NSMutableArray *)getForPostID:(NSString *)postID andBlogURL:(NSString *)blogURL andMediaType:(MediaType)mediaType;
- (BOOL)exists:(NSString *)uniqueID;
- (void)save:(Media *)media;
- (void)insert:(Media *)media;
- (void)update:(Media *)media;
- (void)remove:(Media *)media;
- (void)dataSave;

@end
//
//  AutosaveManager.h
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "Post.h"

@interface AutosaveManager : NSObject {
	WordPressAppDelegate *appDelegate;
}

- (Post *)get:(NSString *)uniqueID;
- (BOOL)exists:(NSString *)uniqueID;
- (void)save:(Post *)post;
- (void)insert:(Post *)post;
- (void)update:(Post *)post;
- (void)remove:(Post *)post;
- (BOOL)hasAutosaves:(NSString *)postID;
- (NSMutableArray *)getForPostID:(NSString *)postID;
- (void)removeAllForPostID:(NSString *)postID;
- (void)removeNewerThan:(NSDate *)date;
- (void)removeOlderThan:(NSDate *)date;
- (void)removeAll;
- (void)dataSave;
- (int)totalAutosavesOnDevice;

@end

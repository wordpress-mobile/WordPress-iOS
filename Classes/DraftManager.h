//
//  DraftManager.h
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "Post.h"

@interface DraftManager : NSObject {
	WordPressAppDelegate *appDelegate;
}

- (Post *)get:(NSString *)uniqueID;
- (NSMutableArray *)getForBlog:(NSString *)blogID;
- (BOOL)exists:(NSString *)uniqueID;
- (void)save:(Post *)post;
- (void)insert:(Post *)post;
- (void)update:(Post *)post;
- (void)remove:(Post *)post;
- (void)dataSave;

@end

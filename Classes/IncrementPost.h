//
//  IncrementPost.h
//  WordPress
//
//  Created by John Bickerstaff on 2/18/10.
//  
//

#import <Foundation/Foundation.h>
#import "XMLRPCRequest.h"
#import "XMLRPCConnection.h"
#import "BlogDataManager.h"


@interface IncrementPost : NSObject {
	
	NSMutableDictionary *currentBlog;
	NSMutableDictionary *currentPost;
	NSArray * next10PostIdArray;
	
	
	
	
	
	int numberOfPostsCurrentlyLoaded;
	
	BlogDataManager *dm;

}

//@property (nonatomic, retain) NSString * postID;
@property int numberOfPostsCurrentlyLoaded;
@property (nonatomic, retain) NSMutableDictionary * currentBlog;
@property (nonatomic, retain) NSMutableDictionary * currentPost;
@property (nonatomic, retain) NSArray *next10PostIdArray;
@property (nonatomic, retain) BlogDataManager *dm;



-(BOOL)loadOlderPosts;
-(BOOL)loadOlderPages;

@end

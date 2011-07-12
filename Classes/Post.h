//
//  Post.h
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import <CoreData/CoreData.h>
#import "WordPressAppDelegate.h"
#import "Category.h"
#import "Coordinate.h"
#import "AbstractPost.h"

@interface Post :  AbstractPost  
{
}

#pragma mark -
#pragma mark Properties
#pragma mark     Attributes
@property (nonatomic, retain) Coordinate * geolocation;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * postFormat;
// We should need to store this, but if we don't send IDs on edits
// custom fields get duplicated and stop working
@property (nonatomic, retain) NSString *latitudeID;
@property (nonatomic, retain) NSString *longitudeID;
@property (nonatomic, retain) NSString *publicID;

// QuickPhoto,...
@property (nonatomic, retain) NSString *specialType;

#pragma mark     Relationships
@property (nonatomic, retain) NSMutableSet * categories;

#pragma mark -
#pragma mark Methods
#pragma mark     Helpers
// Returns categories as a comma-separated list
- (NSString *)categoriesText;
- (void)setCategoriesFromNames:(NSArray *)categoryNames;

#pragma mark     Data Management
// Autosave for local drafts
- (void)autosave;
// Upload a new post to the server
- (void)upload;
//update the post using values retrieved the server
- (void )updateFromDictionary:(NSDictionary *)postInfo;

#pragma mark Class Methods
// Creates an empty local post associated with blog
+ (Post *)newDraftForBlog:(Blog *)blog;
+ (Post *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID;
// Takes the NSDictionary from a XMLRPC call and creates or updates a post
+ (Post *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog;

@end
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AbstractComment.h"
#import "ReaderPost.h"

@interface ReaderComment : AbstractComment

@property (nonatomic, strong) NSNumber *depth;
@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) NSSet *childComments;
@property (nonatomic, strong) ReaderComment *parentComment;
@property (nonatomic, strong) NSAttributedString *attributedContent;

/*
 Fetches comments for the specified post.
 
 @param post The post that owns the comments.
 @param context The managed object context to query.
 
 @return Returns an array of comments.
 */
+ (NSArray *)fetchCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;



+ (NSArray *)fetchChildCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;



+ (NSArray *)fetchParentCommentsForPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;



/*
 Save or update comments for the specified post.
 
 @param comments An array of comment dictionaries to save or update.
 @param post The post that owns the comments.
 @param context The managed object context to query.
 
 @return Returns an array of posts.
 */
+ (void)syncAndThreadComments:(NSArray *)comments forPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;


/**
 Create or update an existing ReaderComment with the specified dictionary.
 
 @param dict A dictionary representing the ReaderComment
 @param post The post that owns the comment.
 @param context The Managed Object Context to fetch from.
 */
+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forPost:(ReaderPost *)post withContext:(NSManagedObjectContext *)context;


@end

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"

@class Media;

@interface AbstractPost : BasePost

// Relationships
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSMutableSet *media;
@property (weak, readonly) AbstractPost *original;
@property (weak, readonly) AbstractPost *revision;
@property (nonatomic, strong) NSMutableSet *comments;
@property (nonatomic, strong) Media *featuredImage;

// Revision management
- (AbstractPost *)createRevision;
- (void)deleteRevision;
- (void)applyRevision;
- (void)updateRevision;
- (BOOL)isRevision;
- (BOOL)isOriginal;
- (void)cloneFrom:(AbstractPost *)source;
- (BOOL)hasSiteSpecificChanges;
- (BOOL)hasPhoto;
- (BOOL)hasVideo;
- (BOOL)hasCategories;
- (BOOL)hasTags;

/**
 *  @brief      Call this method to know whether this post has a revision or not.
 *
 *  @returns    YES if this post has a revision, NO otherwise.
 */
- (BOOL)hasRevision;

/**
 *  @brief      Call this method to know whether this post has unsaved changes or not.
 *
 *  @returns    YES if the post has unsaved changes.  NO otherwise.
 */
- (BOOL)hasUnsavedChanges;

@end

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
@property (nonatomic, strong) NSString *restorableStatus; // Should be used to store the post's status before its moved to the trash.

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


#pragma mark - Unsaved Changes

/**
 *  @brief      Wether the post can be saved or not.
 *
 *  @returns    YES if the post can be saved, NO otherwise.
 */
- (BOOL)canSave;

/**
 *  @brief      Call this method to know if the post has either local or remote unsaved changes.
 *  @details    There should be no need to override this method.  Consider overriding
 *              methods hasLocalChanges and hasRemoteChanges instead.
 *  @returns    YES if there are unsaved changes, NO otherwise.
 */
- (BOOL)hasUnsavedChanges;

/**
 *  @brief      Call this method to know if the post has local changes.
 *  @returns    YES if there are unsaved changes, NO otherwise.
 */
- (BOOL)hasLocalChanges;

/**
 *  @brief      Call this method to know if the post has remote changes.
 *  @returns    YES if there are unsaved changes, NO otherwise.
 */
- (BOOL)hasRemoteChanges;

@end

#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@protocol FeaturedImageDelegate

- (void)gutenbergDidRequestFeaturedImageId:(nonnull NSNumber *)mediaID;

@end

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;
- (void)endEditingAction:(nullable id)sender;

/// The post in a temporary context that the screen is working with.
@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;
/// The original post (or revision) from the main context.
@property (nonnull, nonatomic, strong, readonly) AbstractPost *snapshot;

@property (nonatomic) BOOL isStandalone;
@property (nonnull, nonatomic, strong, readonly) NSArray *publicizeConnections;
@property (nonnull, nonatomic, strong, readonly) NSArray *unsupportedConnections;

@property (nonatomic, weak, nullable) id<FeaturedImageDelegate> featuredImageDelegate;

- (void)reloadData;
- (void)reloadFeaturedImageCell;

@end

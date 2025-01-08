#import <UIKit/UIKit.h>
#import "AbstractPost.h"

// TODO: (kean) figure out if it's still used (presumably yet)
@protocol FeaturedImageDelegate

- (void)gutenbergDidRequestFeaturedImageId:(nonnull NSNumber *)mediaID;

@end

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;

@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;
@property (nonatomic) BOOL isStandalone;
@property (nonnull, nonatomic, strong, readonly) NSArray *publicizeConnections;
@property (nonnull, nonatomic, strong, readonly) NSArray *unsupportedConnections;

@property (nonatomic, weak, nullable) id<FeaturedImageDelegate> featuredImageDelegate;

- (void)reloadData;
- (void)reloadFeaturedImageCell;

@end

#import <UIKit/UIKit.h>
#import "AbstractPost.h"

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

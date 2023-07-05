#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@protocol FeaturedImageDelegate

- (void)gutenbergDidRequestFeaturedImageId:(nonnull NSNumber *)mediaID;

@end

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;
- (void)endEditingAction:(nullable id)sender;

@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;
@property (nonnull, nonatomic, strong, readonly) NSArray *publicizeConnections;

@property (nonatomic, weak, nullable) id<FeaturedImageDelegate> featuredImageDelegate;

- (void)reloadData;

@end

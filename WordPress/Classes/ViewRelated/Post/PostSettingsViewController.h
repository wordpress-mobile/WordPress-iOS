#import <UIKit/UIKit.h>
// For some reason, and only in some files, the modular import does not work.
// Just to be on the safe side, _all_ imports use the angle brackets style.
// We shall try to go back to the modular style on Keystone successfully builds for testing.
// @import WordPressData;
#import <WordPressData/WordPressData.h>

// TODO: It can be removed when the new editor is released. It only exists to support the "Featured" badge on featured images in Gutenberg mobile.
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

@end

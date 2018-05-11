#import "WPImageViewController.h"

@class AbstractPost;
@class FeaturedImageViewController;

@protocol FeaturedImageViewControllerDelegate <NSObject>
- (void)FeaturedImageViewControllerOnRemoveImageButtonPressed:(FeaturedImageViewController *)controller;
@end

@interface FeaturedImageViewController : WPImageViewController

@property (weak, nonatomic) id<FeaturedImageViewControllerDelegate> delegate;

@end

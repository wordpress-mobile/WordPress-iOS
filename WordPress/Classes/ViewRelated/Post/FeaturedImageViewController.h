#import "WPImageViewController.h"

@class FeaturedImageViewController;

@protocol FeaturedImageViewControllerDelegate <NSObject>
- (void)FeaturedImageViewControllerOnRemoveImageButtonPressed:(FeaturedImageViewController *)controller;
@end

@interface FeaturedImageViewController : WPImageViewController

@property (weak, nonatomic) id<FeaturedImageViewControllerDelegate> delegate;

@end

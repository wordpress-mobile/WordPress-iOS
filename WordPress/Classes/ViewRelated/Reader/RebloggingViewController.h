#import <UIKit/UIKit.h>

@class ReaderPost;

@protocol RebloggingViewControllerDelegate;

@interface RebloggingViewController : UIViewController

@property (nonatomic, weak) id<RebloggingViewControllerDelegate> delegate;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;

@end

@protocol RebloggingViewControllerDelegate <NSObject>

- (void)postWasReblogged:(ReaderPost *)post;

@end
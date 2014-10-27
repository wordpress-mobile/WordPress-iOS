#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderCommentsViewController : UIViewController

@property (nonatomic, strong, readonly) ReaderPost *post;

+ (instancetype)controllerWithPost:(ReaderPost *)post;

@end

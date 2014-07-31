#import <UIKit/UIKit.h>

@class Theme;
@class WPWebSnapshotter;

@interface ThemeDetailsViewController : UIViewController

@property(nonatomic) WPWebSnapshotter *webSnapshotter;

- (id)initWithTheme:(Theme*)theme;

@end

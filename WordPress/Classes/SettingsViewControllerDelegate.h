#import <Foundation/Foundation.h>

@protocol SettingsViewControllerDelegate <NSObject>
- (void)controllerDidDismiss:(UIViewController *)controller cancelled:(BOOL)cancelled;
@end

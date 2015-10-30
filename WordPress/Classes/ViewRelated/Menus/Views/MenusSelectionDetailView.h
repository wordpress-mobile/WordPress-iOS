#import <UIKit/UIKit.h>

@interface MenusSelectionDetailView : UIView

- (void)updateWithAvailableLocations:(NSUInteger)numLocationsAvailable selectedLocationName:(NSString *)name;
- (void)updateWithAvailableMenus:(NSUInteger)numMenusAvailable selectedLocationName:(NSString *)name;

@end

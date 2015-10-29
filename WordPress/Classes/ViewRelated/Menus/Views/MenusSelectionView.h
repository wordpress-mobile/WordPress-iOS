#import <UIKit/UIKit.h>

@interface MenusSelectionView : UIView

- (void)updateWithAvailableLocations:(NSUInteger)numLocationsAvailable selectedLocationName:(NSString *)name;
- (void)updateWithAvailableMenus:(NSUInteger)numMenusAvailable selectedLocationName:(NSString *)name;

@end

#import <UIKit/UIKit.h>

@protocol MenusSelectionDetailViewDelegate;

@interface MenusSelectionDetailView : UIView

@property (nonatomic, weak) id <MenusSelectionDetailViewDelegate> delegate;

- (void)updateWithAvailableLocations:(NSUInteger)numLocationsAvailable selectedLocationName:(NSString *)name;
- (void)updateWithAvailableMenus:(NSUInteger)numMenusAvailable selectedLocationName:(NSString *)name;

@end

@protocol MenusSelectionDetailViewDelegate <NSObject>
@optional
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView touchesHighlightedStateChanged:(BOOL)highlighted;
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView tapGestureRecognized:(UITapGestureRecognizer *)tap;

@end
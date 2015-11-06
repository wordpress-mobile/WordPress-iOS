#import <UIKit/UIKit.h>

extern CGFloat const MenusSelectionDetailViewDefaultSpacing;

@protocol MenusSelectionDetailViewDelegate;
@protocol MenusSelectionDetailViewDrawingDelegate;

@interface MenusSelectionDetailView : UIView

@property (nonatomic, weak) id <MenusSelectionDetailViewDelegate> delegate;
@property (nonatomic, weak) id <MenusSelectionDetailViewDrawingDelegate> drawingDelegate;

- (void)updateWithAvailableLocations:(NSUInteger)numLocationsAvailable selectedLocationName:(NSString *)name;
- (void)updateWithAvailableMenus:(NSUInteger)numMenusAvailable selectedLocationName:(NSString *)name;

@end

@protocol MenusSelectionDetailViewDelegate <NSObject>
@optional
- (void)selectionDetailViewPressedForTogglingExpansion:(MenusSelectionDetailView *)detailView;
@end

@protocol MenusSelectionDetailViewDrawingDelegate <NSObject>
- (void)selectionDetailView:(MenusSelectionDetailView *)detailView highlightedDrawingStateChanged:(BOOL)highlighted;
@end
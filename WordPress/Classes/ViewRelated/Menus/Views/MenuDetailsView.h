#import <UIKit/UIKit.h>

@class Menu;

@protocol MenuDetailsViewDelegate;

@interface MenuDetailsView : UIView

@property (nonatomic, strong) Menu *menu;
@property (nonatomic, weak) id <MenuDetailsViewDelegate> delegate;
@property (nonatomic, assign) BOOL savingEnabled;
@property (nonatomic, assign) BOOL isSaving;

@end

@protocol MenuDetailsViewDelegate <NSObject>

- (void)detailsViewUpdatedMenuName:(MenuDetailsView *)menuDetailView;
- (void)detailsViewSelectedToSaveMenu:(MenuDetailsView *)menuDetailView;
- (void)detailsViewSelectedToDeleteMenu:(MenuDetailsView *)menuDetailView;

@end

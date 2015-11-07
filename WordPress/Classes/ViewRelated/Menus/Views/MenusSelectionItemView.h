#import <UIKit/UIKit.h>

@class Menu;
@class MenuLocation;

@interface MenusSelectionViewItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *iconSourceFileName;
@property (nonatomic, strong) id itemObject;
@property (nonatomic, assign) BOOL selected;

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location;

@end

@protocol MenusSelectionItemViewDelegate;

@interface MenusSelectionItemView : UIView

@property (nonatomic, weak) id <MenusSelectionItemViewDelegate> delegate;
@property (nonatomic, strong) MenusSelectionViewItem *item;
@property (nonatomic, weak) MenusSelectionItemView *previousItemView;
@property (nonatomic, weak) MenusSelectionItemView *nextItemView;

@end

@protocol MenusSelectionItemViewDelegate <NSObject>

- (void)selectionItemViewWasSelected:(MenusSelectionItemView *)itemView;

@end
#import <UIKit/UIKit.h>

@interface MenuItemSourceTextBarFieldObserver : NSObject

@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, copy) void(^onTextChange)(NSString *text);

@end

@protocol MenuItemSourceTextBarDelegate;

@interface MenuItemSourceTextBar : UIView

@property (nonatomic, weak) id <MenuItemSourceTextBarDelegate> delegate;
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UITextField *textField;

- (id)initAsSearchBar;
- (void)addTextObserver:(MenuItemSourceTextBarFieldObserver *)textObserver;

@end

@protocol MenuItemSourceTextBarDelegate <NSObject>

- (void)sourceTextBarDidBeginEditing:(MenuItemSourceTextBar *)textBar;
- (void)sourceTextBarDidEndEditing:(MenuItemSourceTextBar *)textBar;
- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(NSString *)text;

@end

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Object for configuring infrequent updates on a textField's text changes.
 */
@interface MenuItemSourceTextBarFieldObserver : NSObject

@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, copy, nullable) void(^onTextChange)(NSString *text);

@end

@protocol MenuItemSourceTextBarDelegate;

@interface MenuItemSourceTextBar : UIView

@property (nonatomic, weak, nullable) id <MenuItemSourceTextBarDelegate> delegate;

/**
 Icon imagView to the left of the textField.
 */
@property (nonatomic, strong, readonly) UIImageView *iconView;

/**
 Input textField for the bar.
 */
@property (nonatomic, strong, readonly) UITextField *textField;

/**
 Configure as a searchBar.
 */
- (id)initAsSearchBar;

/**
 Add an observer for onTextChange events within MenuItemSourceTextBarFieldObserver.
 */
- (void)addTextObserver:(MenuItemSourceTextBarFieldObserver *)textObserver;

@end

@protocol MenuItemSourceTextBarDelegate <NSObject>

- (void)sourceTextBarDidBeginEditing:(MenuItemSourceTextBar *)textBar;
- (void)sourceTextBarDidEndEditing:(MenuItemSourceTextBar *)textBar;
- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END

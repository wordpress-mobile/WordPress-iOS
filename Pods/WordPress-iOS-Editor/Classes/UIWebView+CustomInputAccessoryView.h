#import <UIKit/UIKit.h>

@interface UIWebView (CustomInputAccessoryView)

/**
 *	@brief		The custom input accessory view.
 */
@property (nonatomic, strong, readwrite) UIView* customInputAccessoryView;

/**
 *	@brief		Wether the UIWebView will return the custom or the default accessory view.
 */
@property (nonatomic, assign, readwrite) BOOL usesCustomInputAccessoryView;

@end

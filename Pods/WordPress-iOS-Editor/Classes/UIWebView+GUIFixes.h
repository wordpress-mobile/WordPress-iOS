#import <UIKit/UIKit.h>

@interface UIWebView (GUIFixes)

/**
 *	@brief		The custom input accessory view.
 */
@property (nonatomic, strong, readwrite) UIView* customInputAccessoryView;

/**
 *	@brief		Wether the UIWebView will use the fixes provided by this category or not.
 */
@property (nonatomic, assign, readwrite) BOOL usesGUIFixes;

@end

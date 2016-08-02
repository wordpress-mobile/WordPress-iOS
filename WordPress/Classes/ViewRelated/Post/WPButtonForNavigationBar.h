#import <UIKit/UIKit.h>

/**
 *	@class		WPButtonForNavigationBar
 *	@brief		Special button for use in navigation bars.
 *	@details	This class can remove the extra spacing between bar button items, making layout
 *				in nav bars easier.
 */
@interface WPButtonForNavigationBar : UIButton

#pragma mark - Custom spacing

/**
 *	@brief		The spacing to the left of the button.
 *	@details	Keep in mind this does not override the default spacing, but is added to it.  To
 *				remove the default spacing use the properties below.
 */
@property (nonatomic, assign, readwrite) CGFloat leftSpacing;

/**
 *	@brief		The spacing to the right of the button.
 *	@details	Keep in mind this does not override the default spacing, but is added to it.  To
 *				remove the default spacing use the properties below.
 */
@property (nonatomic, assign, readwrite) CGFloat rightSpacing;

#pragma mark - Default spacing

/**
 *	@brief		If set the YES, the default spacing to the left of the button is removed.
 *	@details	Set this to YES on left aligned buttons.  If this is set to YES, you should make
 *				sure the button to the left of this one has removeDefaultRightSpacing set to NO.
 */
@property (nonatomic, assign, readwrite) BOOL removeDefaultLeftSpacing;

/**
 *	@brief		If set the YES, the default spacing to the right of the button is removed.
 *	@details	Set this to YES on right aligned buttons.  If this is set to YES, you should make
 *				sure the button to the right of this one has removeDefaultLeftSpacing set to NO.
 */
@property (nonatomic, assign, readwrite) BOOL removeDefaultRightSpacing;

@end
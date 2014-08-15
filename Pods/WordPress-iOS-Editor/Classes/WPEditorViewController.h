#import <UIKit/UIKit.h>
#import "HRColorPickerViewController.h"

@class WPEditorViewController;

@protocol WPEditorViewControllerDelegate <NSObject>

typedef enum
{
	kWPEditorViewControllerModePreview = 0,
	kWPEditorViewControllerModeEdit
}
WPEditorViewControllerMode;

@optional

- (void)editorDidBeginEditing:(WPEditorViewController *)editorController;
- (void)editorDidEndEditing:(WPEditorViewController *)editorController;

- (void)editorTitleDidChange:(WPEditorViewController *)editorController;
- (void)editorTextDidChange:(WPEditorViewController *)editorController;

- (void)editorDidPressSettings:(WPEditorViewController *)editorController;
- (void)editorDidPressMedia:(WPEditorViewController *)editorController;
- (void)editorDidPressPreview:(WPEditorViewController *)editorController;

@end

@class ZSSBarButtonItem;

@interface WPEditorViewController : UIViewController

@property (nonatomic, weak) id<WPEditorViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *bodyText;
@property (nonatomic) BOOL isShowingKeyboard;


#pragma mark - Initializers

/**
 *	@brief		Initializes the VC with the specified mode.
 *
 *	@param		mode	The mode to initialize the VC in.
 *
 *	@returns	The initialized object.
 */
- (instancetype)initWithMode:(WPEditorViewControllerMode)mode;

#pragma mark - Editing

/**
 *	@brief		Use this method to know if the user is currently editing the content.
 */
- (BOOL)isEditing;

/**
 *	@brief		Enables editing.
 */
- (void)enableEditing;

/**
 *	@brief		Disables editing.
 */
- (void)disableEditing;

/**
 *	@brief		Starts editing.
 */
- (void)startEditing;

/**
 *  @brief		Stop all editing activities.
 */
- (void)stopEditing;

#pragma mark - Override these in subclasses

/**
 *  Gets called when the insert URL picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertURLAlternatePicker;

/**
 *  Gets called when the insert Image picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertImageAlternatePicker;

@end

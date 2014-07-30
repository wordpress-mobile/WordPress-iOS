#import <UIKit/UIKit.h>
#import "HRColorPickerViewController.h"

@class WPEditorViewController;

@protocol WPEditorViewControllerDelegate <NSObject>

@optional

- (BOOL)editorShouldBeginEditing:(WPEditorViewController *)editorController;

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

/**
 *  Stop all editing activities.
 */
- (void)stopEditing;

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

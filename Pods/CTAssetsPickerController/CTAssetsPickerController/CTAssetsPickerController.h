/*
 CTAssetsPickerController.h
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */


#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>



@protocol CTAssetsPickerControllerDelegate;

/**
 *  A controller that allows picking multiple photos and videos from user's photo library.
 */
@interface CTAssetsPickerController : UINavigationController

/**
 *  The assets picker’s delegate object.
 */
@property (nonatomic, weak) id <UINavigationControllerDelegate, CTAssetsPickerControllerDelegate> delegate;

/**
 *  Set the `ALAssetsFilter` to filter the picker contents.
 */
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;

/**
 *  The selected assets.
 *
 *  It contains selected `ALAsset` objects. The order of the objects is the selection order.
 *  
 *  You can use this property to select assets initially when presenting the picker.
 */
@property (nonatomic, strong) NSMutableArray *selectedAssets;

/**
 *  Determines whether or not the cancel button is visible in the picker.
 *
 *  The cancel button is visible by default. To hide the cancel button, (e.g. presenting the picker in `UIPopoverController`)
 *  set this property’s value to `NO`.
 */
@property (nonatomic, assign) BOOL showsCancelButton;


/**
 *  @name Managing Selections
 */

/**
 *  Selects an asset in the picker.
 *
 *  @param asset The asset to be selected.
 */
- (void)selectAsset:(ALAsset *)asset;

/**
 *  Deselects an asset in the picker.
 *
 *  @param asset The asset to be deselected.
 */
- (void)deselectAsset:(ALAsset *)asset;

@end


/**
 *  The `CTAssetsPickerControllerDelegate` protocol defines methods that allow you to to interact with the assets picker interface
 *  and manage the selection and highlighting of assets in the picker.
 *
 *  The methods of this protocol notify your delegate when the user selects, highlights, finish picking assets, or cancels the picker operation.
 *
 *  The delegate methods are responsible for dismissing the picker when the operation completes.
 *  To dismiss the picker, call the `dismissViewControllerAnimated:completion:` method of the presenting controller
 *  responsible for displaying `CTAssetsPickerController` object.
 *
 *  The picked assets can be processed by accessing the `defaultRepresentation` property.
 *  It returns an `ALAssetRepresentation` object which encapsulates one of the representations of `ALAsset` object.
 */
@protocol CTAssetsPickerControllerDelegate <NSObject>


/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `ALAsset` objects.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets picker interface.
 */
- (void)assetsPickerControllerDidCancel:(CTAssetsPickerController *)picker;


/**
 *  @name Enabling Assets Group
 */

/**
 *  Ask the delegate if the specified assets group should be shown.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param group  The assets group to be shown.
 *
 *  @return `YES` if the assets group should be shown or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group;


/**
 *  @name Enabling Assets for Selection
 */

/**
 *  Ask the delegate if the specified asset should be enabled for selection.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be enabled.
 *
 *  @return `YES` if the asset should be enabled or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldEnableAsset:(ALAsset *)asset;


/**
 *  @name Managing the Selected Assets
 */

/**
 *  Asks the delegate if the specified asset should be selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be selected.
 *
 *  @return `YES` if the asset should be selected or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was selected.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didSelectAsset:(ALAsset *)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldDeselectAsset:(ALAsset *)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was deselected.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didDeselectAsset:(ALAsset *)asset;



/**
 *  @name Managing Asset Highlighting
 */

/**
 *  Asks the delegate if the specified asset should be highlighted.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be highlighted.
 *
 *  @return `YES` if the asset should be highlighted or `NO` if it should not.
 */
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldHighlightAsset:(ALAsset *)asset;

/**
 *  Tells the delegate that asset was highlighted.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that was highlighted.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didHighlightAsset:(ALAsset *)asset;


/**
 *  Tells the delegate that the highlight was removed from the asset.
 *
 *  @param picker    The controller object managing the assets picker interface.
 *  @param indexPath The asset that had its highlight removed.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didUnhighlightAsset:(ALAsset *)asset;



/**
 *  @name Notifications
 */

/**
 *  Sent when the assets selected or deselected
 *
 *  The notification’s `object` is an `NSArray` object of selected assets
 */
extern NSString * const CTAssetsPickerSelectedAssetsChangedNotification;


@end
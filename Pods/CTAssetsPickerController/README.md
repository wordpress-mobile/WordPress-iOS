# CTAssetsPickerController

CTAssetsPickerController v2 released! It has newly re-design delegate methods, fixed serveral issues and improved usability. Please see [What's new](#whats-new) for the details.

## Introduction

CTAssetsPickerController is an iOS controller that allows picking multiple photos and videos from user's photo library. The usage and look-and-feel are just similar to UIImagePickerController. It uses **ARC** and requires **AssetsLibrary** framework.

![Screenshot](Screenshot.png "Screenshot")

## Features
1. Picks multiple photos and videos across albums from user's library.
2. Filters assets for picking only photos or videos.
3. Provides delegate methods for customization.
4. Achieves average 5x fps.
5. Conforms UIAccessibility Protocol.


## What's new
* [Release Notes](RELEASE-NOTES.md)

#### Note
CTAssetsPickerController has dropped support for iOS 6. To use this control with iOS 6, you might consider to checkout the obsolete branch [1.x.x](https://github.com/chiunam/CTAssetsPickerController/tree/1.x.x), which developement has been ceased.


## Minimum Requirement
Xcode 5 and iOS 7.

## Installation

### via [CocoaPods](http://cocoapods.org)

````bash
$ edit Podfile
platform :ios, '7.0'
pod 'CTAssetsPickerController',  '~> 2.2.0'
$ pod install
````
* Use the Xcode workspace instead of the project.

### via Git Submodules

````bash
$ git submodule add http://github.com/chiunam/CTAssetsPickerController
````
1. Drag `CTAssetsPickerController` folder in your project and add to your targets.
2. Add `AssetsLibrary.framework`.

## Simple Uses

See the demo project and [documentation](#documentation) for the details.

### Import header

```` objective-c
#import <CTAssetsPickerController.h>
````

### Create and present CTAssetsPickerController

```` objective-c
CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
picker.delegate = self;
[self presentViewController:picker animated:YES completion:nil];
````

### Implement didFinishPickingAssets delegate

The delegate methods are responsible for dismissing the picker when the operation completes. To dismiss the picker, call the [dismissViewControllerAnimated:completion:](https://developer.apple.com/library/ios/documentation/uikit/reference/UIViewController_Class/Reference/Reference.html#//apple_ref/occ/instm/UIViewController/dismissViewControllerAnimated:completion:) method of the presenting controller responsible for displaying `CTAssetsPickerController` object. Please refer to the demo app.

```` objective-c
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets;
// assets contains ALAsset objects.
````

## Advanced Uses

Customization can be done by setting properties or implementating delegate methods. This section describes common customizations. Please refer to the [documentation](#documentation) for the complete list of properties and delegate methods.

### Properties

**Filter picker contents**

Pick only photos or videos by creating an `ALAssetsFilter` and assigning it to `assetsFilter`.
```` objective-c
picker.assetsFilter = [ALAssetsFilter allPhotos]; // Only pick photos.
````

**Hide cancel button**

Hide cancel button if you present the picker in `UIPopoverController`.
```` objective-c
picker.showsCancelButton = NO;
````

**Override picker's title**

Override title of the albums selection screen.
```` objective-c
picker.title = @"Pick photos";
````

**Set initially selected assets**

Set selected assets by assigning an `NSMutableArray` to `selectedAssets`.
```` objective-c
picker.selectedAssets = [NSMutableArray arrayWithArray:@[asset1, asset2, asset3, ...]];
````

### Delegate Methods

**Set maximum number of selections**

Limit the number of assets to be picked.
```` objective-c
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}
````

**Disable assets**

Enable only certain assets to be selected.
```` objective-c
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldEnableAsset:(ALAsset *)asset
{
    // Enable video clips if they are at least 5s
    if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
    {
        NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
        return lround(duration) >= 5;
    }
    // Photos are always enabled
    else
    {
        return YES;
    }
}
````

**Hide albums**

Assets stored on iCloud (photo stream) may not be displayed and picked properly if they have not downloaded to the device. You may hide iCloud albums by implementing the following delegate.
```` objective-c
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldShowAssetsGroup:(ALAssetsGroup *)group
{
    // Do not show photo stream
    NSInteger type = [[group valueForProperty:ALAssetsGroupPropertyType] integerValue];
    return (type != ALAssetsGroupPhotoStream);
}
````

**Show alert on selection**

Or show an alert when user try to select empty assets

```` objective-c
- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    // Show alert when user try to select assets that have not been downloaded
    if (!asset.defaultRepresentation)
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Attention"
                                   message:@"Your asset has not yet been downloaded to your device"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];

        [alertView show];
    }

    return (asset.defaultRepresentation != nil);
}
````

### Notifications

An `NSNotification` object named `CTAssetsPickerSelectedAssetsChangedNotification` will be sent when user select or deselect assets. You may add your observer to monitor the change of selection.


## Documentation
* [Online documentation](http://chiunam.github.io/CTAssetsPickerController)
* If you have [Appledoc](https://github.com/tomaz/appledoc) installed, you can also install the documentation to Xcode by running the `Documentation` target of the demo project.


## Note
CTAssetsPickerController does not compress the picked photos and videos. You can process the picked assets via the `defaultRepresentation` property.

For example, you can create `UIImage` from picked assets like this:-

```` objective-c
    ALAssetRepresentation *representation = alAsset.defaultRepresentation;

    UIImage *fullResolutionImage =
    [UIImage imageWithCGImage:representation.fullResolutionImage
                        scale:1.0f
                  orientation:(UIImageOrientation)representation.orientation];
````

and create `NSData` of picked vidoes:-

```` objective-c
    ALAssetRepresentation *representation = alAsset.defaultRepresentation;

    NSURL *url          = representation.url;
    AVAsset *asset      = [AVURLAsset URLAssetWithURL:url options:nil];

    AVAssetExportSession *session =
    [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetLowQuality];

    session.outputFileType  = AVFileTypeQuickTimeMovie;
    session.outputURL       = VIDEO_EXPORTING_URL;

    [session exportAsynchronouslyWithCompletionHandler:^{

        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSData *data    = [NSData dataWithContentsOfURL:session.outputURL];
        }

    }];

````
Please refer the documentation of `ALAssetRepresentation` and `AVAssetExportSession`.


## License

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

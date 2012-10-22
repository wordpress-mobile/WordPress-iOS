//
//  CameraPlusPickerHelper.h
//  PickerAPITester
//
//  Created by Karl von Randow on 28/08/11.
//  Copyright 2011 XK72 Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

/* Picker modes. Set these modes on the CameraPlusPickerManager to open the Camera+ picker in a
 * specific mode.
 */
typedef enum {
    
    /* Picker modes */
    CameraPlusPickerModeShootAndLightbox = 1,
    CameraPlusPickerModeShootOnly,
    CameraPlusPickerModeLightboxOnly,
 
    /* Edit mode is invoked with the special openCameraPlusEditorWithImage... selectors */
    CameraPlusPickerModeEdit
    
} CameraPlusPickerMode;

@class CameraPlusPickedImages;

#if NS_BLOCKS_AVAILABLE

typedef void (^CameraPlusPickerCompletionBlock)(CameraPlusPickedImages *images);
typedef void (^CameraPlusPickerCancelBlock)();

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol CameraPlusPickerManagerDelegate;

@interface CameraPlusPickerManager : NSObject {
@private
    NSString *callbackURLProtocol;
    int maxImages;
    CameraPlusPickerMode mode;
    int imageSize;
}


////////////////////////////////////////////////////////////////////////////////////////////////////

/* Access the shared CameraPlusPickerManager */

+ (CameraPlusPickerManager*)sharedManager;


/* Test whether Camera+ is installed on the device. */
@property (nonatomic, readonly) BOOL cameraPlusAvailable;

/* Test whether Camera+ with picker support is installed. If Camera+ is available, but the
 * picker isn't available, the user has an outdated version of Camera+ and could be invited
 * to upgrade.
 */
@property (nonatomic, readonly) BOOL cameraPlusPickerAvailable;

/* Set a url protocol for Camera+ to use to launch your app after using the picker. This url protocol
 * must be configured in your Info.plist.
 */
@property (nonatomic, strong) NSString *callbackURLProtocol;

/* The picker mode, see the CameraPlusPickerMode enum. Set this before invoking the 
 * openCameraPlusPicker selector. The picker mode is also set before the delegate
 * selectors are invoked, to represent the mode used to pick the returned images.
 */
@property (nonatomic, assign) CameraPlusPickerMode mode;

/* The maximum size in pixels for the longest side of the image. For example if you
 * set 1000 here the longest side of the image will be no bigger than 1000 pixels.
 * Aspect ratio is always maintained when resizing.
 * Defaults to 0 meaning no resizing.
 */
@property (nonatomic, assign) int imageSize;

/* Set to the maximum number of images to be picked in Camera+. Defaults to 1.
 * This must be set before you invoke the openCameraPlus... selectors.
 */
@property (nonatomic, assign) int maxImages;



/* Open the Camera+ picker */
- (BOOL)openCameraPlusPicker;
- (BOOL)openCameraPlusPickerWithMode:(CameraPlusPickerMode)mode;


/* Open the Camera+ editor */
- (BOOL)openCameraPlusEditorWithImage:(UIImage*)image;
- (BOOL)openCameraPlusEditorWithImageData:(NSData*)imageData;


////////////////////////////////////////////////////////////////////////////////////////////////////


/* Returns YES if the given url is a Camera+ picker callback, and should be handled by
 * the handleCameraPlusPickerCallback selector.
 */
- (BOOL)shouldHandleURLAsCameraPlusPickerCallback:(NSURL*)url;

/* Handle the callback from Camera+. This is invoked from the UIApplicationDelegate's
 * application:handleOpenURL:.
 */
- (void)handleCameraPlusPickerCallback:(NSURL*)url delegate:(id<CameraPlusPickerManagerDelegate>)delegate;

#if NS_BLOCKS_AVAILABLE
- (void)handleCameraPlusPickerCallback:(NSURL*)url 
                            usingBlock:(CameraPlusPickerCompletionBlock)block
                           cancelBlock:(CameraPlusPickerCancelBlock)cancelBlock;
#endif

/* Utility method to create a dictionary compatible with the UIImagePickerControllerDelegate 
 * info dictionary.
 */
+ (NSDictionary*)imagePickerControllerInfoDictionaryForImage:(UIImage*)image metadata:(NSDictionary*)metadata;

@end



#pragma mark - Delegate

@protocol CameraPlusPickerManagerDelegate <NSObject>

- (void)cameraPlusPickerManager:(CameraPlusPickerManager *)manager
                  didPickImages:(CameraPlusPickedImages *)images;

@optional

- (void)cameraPlusPickerManagerDidCancel:(CameraPlusPickerManager *)manager;

@end



#pragma mark -

@interface CameraPlusPickedImages : NSObject {
@private
    UIPasteboard *pasteboard;
}

@property (nonatomic, readonly) int numberOfImages;

- (id)initWithPasteboard:(UIPasteboard *)aPasteboard;

- (UIImage *)imageAtIndex:(NSUInteger)i;
- (NSData *)imageDataAtIndex:(NSUInteger)i;
- (NSDictionary *)metadataAtIndex:(NSUInteger)i;

- (UIImage *)image;
- (NSArray *)images;

@end
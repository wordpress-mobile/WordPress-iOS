//
//  MediaViewController.h
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "WordPressAppDelegate.h"
#import "PostViewController.h"
#import "UIDevice-Hardware.h"
#import "Media.h"

@interface MediaViewController : UITableViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	NSMutableArray *mediaArray;
    NSManagedObjectContext *managedObjectContext;
    UIBarButtonItem *addButton;
    PostViewController *postDetailViewController;
	WordPressAppDelegate *wpAppDelegate;
}

@property (nonatomic, retain) NSMutableArray *mediaArray;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, retain) WordPressAppDelegate *wpAppDelegate;

- (void)addMedia;
- (void)pickMediaFromPhotoLibrary;
- (void)pickPhotoFromCamera;
- (void)pickVideoFromCamera;
- (void)pickAudioFromMicrophone;
- (void)saveMedia:(NSString *)localURL thumbnail:(NSData *)thumbnail mediaType:(NSString *)mediaType;
- (void)fetchMedia;
- (UIImage *)generateThumbnail:(UIImage *)fromImage;

@end

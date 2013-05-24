//
//  QuickPhotoViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "QuickPhotoViewController.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "Media.h"
#import "CameraPlusPickerManager.h"
#import "WPPopoverBackgroundView.h"

@interface QuickPhotoViewController () {
    UIPopoverController *popController;
    BOOL showPickerAfterRotation;
}

@property (nonatomic, strong) UIPopoverController *popController;

- (void)showPicker;
- (void)handleKeyboardWillShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end

@implementation QuickPhotoViewController

@synthesize photoImageView;
@synthesize titleTextField;
@synthesize contentTextView;
@synthesize blogSelector;
@synthesize postButtonItem;
@synthesize photo;
@synthesize sourceType;
@synthesize isCameraPlus;
@synthesize sidebarViewController;
@synthesize startingBlog;
@synthesize popController;


- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.photoImageView.delegate = nil;
    self.popController.delegate = nil;
}

- (id)initWithPost:(Post *)aPost {
    if (self = [super initWithNibName:@"QuickPhotoViewController" bundle:nil]) {
        post = aPost;
    }
    
    return self;
}

#if !__has_feature(objc_arc)
//stackoverflow.com/questions/945082/uiwebview-in-multithread-viewcontroller
- (oneway void)release {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    } else {
        [super release];
    }
}
#endif

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.titleTextField.placeholder = NSLocalizedString(@"Title (optional)", @"Quick Photo title");
    [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
    self.blogSelector.delegate = self;
    if (self.startingBlog != nil) {
        self.blogSelector.activeBlog = startingBlog;
        // if we are opening an existing post disable the blog selection since the photo
        // may already be uploaded and used in another post, maybe not required
        if (post) {
            [self.blogSelector setEnabled:NO];
        }
    }
    
    if (self.photo) {
        self.photoImageView.image = self.photo;
        [self saveImage];
    }
    self.photoImageView.delegate = self;
    self.title = NSLocalizedString(@"Quick Photo", @"");
    self.postButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"") 
                                                            style:UIBarButtonItemStyleDone 
                                                           target:self 
                                                           action:@selector(post)];

    [postButtonItem setEnabled:(post != nil)];
    self.navigationItem.rightBarButtonItem = self.postButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (post) {
        titleTextField.text = post.postTitle;
        contentTextView.text = post.content;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    startingFrame = self.view.frame;
    if (self.photo == nil) {
        [self showPicker];
    } else {
        self.photoImageView.image = self.photo;
    }
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.photoImageView.delegate = nil;
    self.photoImageView = nil;
    self.titleTextField = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;
    self.blogSelector.delegate = nil;
    self.blogSelector = nil;

    self.popController.delegate = nil;
    self.popController = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (IS_IPAD || interfaceOrientation == UIDeviceOrientationPortrait) 
        return YES;
    else 
        return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (self.popController) {
        showPickerAfterRotation = YES;
        [popController dismissPopoverAnimated:NO];
        self.popController = nil;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (showPickerAfterRotation) {
        showPickerAfterRotation = NO;
        [self showPicker];
    }
}


#pragma mark -
#pragma mark Custom methods

- (void)showPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = self.sourceType;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
    picker.allowsEditing = NO;
    picker.delegate = self;
    
    if (IS_IPAD) {
        self.popController = [[UIPopoverController alloc] initWithContentViewController:picker];
        if ([popController respondsToSelector:@selector(popoverBackgroundViewClass)]) {
            popController.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
        }
        popController.delegate = self;
        CGRect rect = CGRectMake((self.view.frame.size.width/2), 1.0f, 1.0f, 1.0f); // puts the arrow in the middle of the screen
        [popController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];            
        
    } else {
        picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:picker animated:YES];
    }
}


- (void)handleKeyboardWillShow:(NSNotification *)notification {

    NSDictionary *info = notification.userInfo;

    keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect rect = [self.view convertRect:keyboardFrame fromView:self.view.window];

    CGRect frm = startingFrame;
    frm.size.height = rect.origin.y;

    self.view.frame = frm;
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
    self.view.frame = startingFrame;
    keyboardFrame = CGRectZero;
}

- (void)postInBackground {
    [post save];
}

- (void)initializePost {
    Blog *blog = self.blogSelector.activeBlog;
    Media *media = nil;
    if (post == nil) {
        post = [Post newDraftForBlog:blog];
    } else {
        media = [post.media anyObject];
        
        // if the blog selected at publish time doesn't match the blog that
        // the media was uploaded to then remove the media and create a
        // new one to be uploaded to the proper blog
        if (media.blog != blog) {
            Media *newMedia = [self createMediaForPost:post];
            
            media.posts = nil;
            [media deleteWithSuccess:^() {
                 [FileLogger log:@"%@ %@ Media removed from blog (%@)", self, NSStringFromSelector(_cmd), media];
            } failure:nil];
            
            media = newMedia;
        }
        
        post.blog = blog;
        [media setBlog:blog];
    }
    post.postTitle = titleTextField.text;
    post.content = contentTextView.text;
    if (self.isCameraPlus) {
        post.specialType = @"QuickPhotoCameraPlus";
    } else {
        post.specialType = @"QuickPhoto";
    }
    post.postFormat = @"image";
    [post save];
}

// currently unused as there is no button in the UI to call this action
- (IBAction)openPostInFullEditor:(id)sender {
    [self initializePost];
    Media *media = [post.media anyObject];
    if (!media.isUploaded && !media.isUploading) {
        [media uploadWithSuccess:^{
            if ([media isDeleted]) {
                [FileLogger log:@"%@ %@ Media deleted while uploading (%@)", self, NSStringFromSelector(_cmd), media];
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldInsertMediaBelow" object:media];
            
            [media save];
        } failure:^(NSError *error) {
            [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
        } progressUpdate:nil];
    }
    
    [self dismiss:NO];
    [sidebarViewController editPost:post];
}

- (void)post {
    [self initializePost];
    Media *media = [post.media anyObject];
    if (!media.isUploaded) {
        // subscribe to notifications so the post can be updated after the media has been uploaded
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:media];
        [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:media];
    } else {
        post.content = [NSString stringWithFormat:@"%@\n\n%@", [media html], post.content];
    }
    
    if( appDelegate.connectionAvailable == YES ) {
        if (post.remoteStatus != AbstractPostRemoteStatusPushing) {
            appDelegate.isUploadingPost = YES;
            // mark the post as uploading right away so that it's not editable in the posts view
            // if the post fails it will be marked as failed (fixes #1472)
            [post setRemoteStatus:AbstractPostRemoteStatusPushing];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                // start uploading the media if it hasn't started/completed yet
                if (!media.isUploading && !media.isUploaded) {
                    [media uploadWithSuccess:nil failure:^(NSError *error) {
                        [sidebarViewController postUploadFailed:nil];
                    } progressUpdate:^(float progress) {
                        [sidebarViewController updateQuickPostProgress:progress];
                    }];
                } else if (media.isUploaded) {
                    [sidebarViewController updateQuickPostProgress:1.0f];
                    [post uploadWithSuccess:nil failure:nil];
                } 
                [post save];
            });
            
            
        }
        [sidebarViewController uploadQuickPhoto:post];
        [self dismiss];
    } else {
        [media setRemoteStatus:MediaRemoteStatusFailed];
        [post save];
        [self dismiss];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                            message:NSLocalizedString(@"The Internet connection appears to be offline. The post has been saved as a local draft, you can publish it later.", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)dismiss {
    [self dismiss:YES];
}

- (void)dismiss:(BOOL)animated {
    [[self sidebarViewController] dismissModalViewControllerAnimated:animated];
}

- (void)cancel {
    self.photo = nil;
    if (post != nil) {
        Media *media = [post.media anyObject];
        if (media) {
            [media remove];
            if (media.isUploaded) {
                [media deleteWithSuccess:nil failure:nil];
            }
        }
        [post deletePostWithSuccess:nil failure:nil];
    }
    [self dismiss];
}

- (Media*)createMediaForPost:(Post *)p {
    Media* media = [Media newMediaForPost:p];
    int resizePreference = 0;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
        resizePreference = [[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] intValue];
    
    MediaResize newSize = kResizeLarge;
    switch (resizePreference) {
        case 1:
            newSize = kResizeSmall;
            break;
        case 2:
            newSize = kResizeMedium;
            break;
        case 4:
            newSize = kResizeOriginal;
            break;
    }
    
    [media setImage:self.photo withSize:newSize];
    [FileLogger log:@"%@ %@ Image size after optimization: %dKB", self, NSStringFromSelector(_cmd), [media.filesize intValue]];
    return media;
}

- (void)saveImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (self.sourceType == UIImagePickerControllerSourceTypeCamera)
            UIImageWriteToSavedPhotosAlbum(self.photo, nil, nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            Media *media = nil;
            
            Blog *blog = self.blogSelector.activeBlog;
            startingBlog = blog;
            if (post == nil) {
                post = [Post newDraftForBlog:blog];
            }
            
            if (post.media && [post.media count] > 0) {
                media = [post.media anyObject];
            } else {
                media = [self createMediaForPost:post];
            }
            
            [media save];
            [postButtonItem setEnabled:YES];

            // start uploading the media right away
            if (!media.isUploaded) {
                [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:media];
                
                appDelegate.isUploadingPost = YES;
                [media uploadWithSuccess:^{
                    if ([media isDeleted]) {
                        [FileLogger log:@"%@ %@ Media deleted while uploading (%@)", self, NSStringFromSelector(_cmd), media];
                        return;
                    }
                    [media save];
                } failure:^(NSError *error) {
                    [sidebarViewController postUploadFailed:nil];
                } progressUpdate:^(float progress) {
                    [sidebarViewController updateQuickPostProgress:progress];
                }];
            }
        });
    });
}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (popController) {
        [popController dismissPopoverAnimated:YES];
        self.popController = nil;
    }
    
    self.photo = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    self.photoImageView.image = self.photo;
    
    if (![self isViewLoaded]) {
        // If we get a memory warning on the way here our view could have unloaded.
        // In order to prevet a crash we'll make sure its loaded before 
        // dismissing the modal. 
        [self view];
        [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
        self.blogSelector.delegate = self;
        
        // if the keyboard is showing we need to reset the height of the view as well.
        if (!CGRectEqualToRect(keyboardFrame, CGRectZero)) {
            CGRect frame = self.view.frame;
            frame.size.height = keyboardFrame.size.height;
            self.view.frame = frame;
        }
    }
    
    [picker dismissModalViewControllerAnimated:NO];
    [self saveImage];
    
    [self.titleTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.f];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    picker.delegate = nil;
    [self dismiss];
}

#pragma mark - Blog selector delegate

- (void)blogSelectorButtonWillBecomeActive:(BlogSelectorButton *)button {
    [self.titleTextField resignFirstResponder];
    [self.contentTextView resignFirstResponder];
    [self.view bringSubviewToFront:button];
}

- (void)blogSelectorButtonDidBecomeInactive:(BlogSelectorButton *)button {
    [self.titleTextField becomeFirstResponder];
}

#pragma mark - Quick Photo preview view delegate

- (void)pictureWillZoom {
    [self.titleTextField resignFirstResponder];
    [self.contentTextView resignFirstResponder];
    [self.view bringSubviewToFront:photoImageView];
}

- (void)pictureDidRestore {
    [self.titleTextField becomeFirstResponder];
}

#pragma mark - UIPopoverViewController Delegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self dismiss];
}

@end

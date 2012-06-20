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

@interface QuickPhotoViewController () {
    UIPopoverController *popController;
}

@property (nonatomic, retain) UIPopoverController *popController;

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
    self.photoImageView = nil;
    self.titleTextField = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;
    self.sidebarViewController = nil;
    self.startingBlog = nil;
    self.popController.delegate = nil;
    self.popController = nil;
    
    [super dealloc];
}

//stackoverflow.com/questions/945082/uiwebview-in-multithread-viewcontroller
- (oneway void)release {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    } else {
        [super release];
    }
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.titleTextField.placeholder = NSLocalizedString(@"Title (optional)", @"Quick Photo title");
    [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
    self.blogSelector.delegate = self;
    self.blogSelector.activeBlog = startingBlog;
    
    if (self.photo) {
        self.photoImageView.image = self.photo;
        [self saveImage];
    }
    self.photoImageView.delegate = self;
    self.navigationItem.title = NSLocalizedString(@"Quick Photo", @"");
    self.postButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)] autorelease];
    [postButtonItem setEnabled:NO];
    self.navigationItem.rightBarButtonItem = self.postButtonItem;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    startingFrame = self.view.frame;
    if (self.photo == nil) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = self.sourceType;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        picker.allowsEditing = NO;
        picker.delegate = self;

        if (IS_IPAD) {
            //Hmm... what to do here?
            self.popController = [[UIPopoverController alloc] initWithContentViewController:picker];
            popController.delegate = self;
            CGRect rect = CGRectMake((self.view.frame.size.width/2), 1.0f, 1.0f, 1.0f);
            [popController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];            
            
        } else {
            picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentModalViewController:picker animated:YES];
        }
        [picker release];
    } else {
        [self.titleTextField becomeFirstResponder];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Custom methods

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect frame = startingFrame;
    frame.size.height = frame.size.height - keyboardFrame.size.height;
    [self.view setFrame:frame];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    self.view.frame = startingFrame;
    keyboardFrame = CGRectZero;
}

- (void)postInBackground {
    [post save];
}

- (void)post {
    Blog *blog = self.blogSelector.activeBlog;
    Media *media = nil;
    if (post == nil) {
        post = [Post newDraftForBlog:blog];
    } else {
        post.blog = blog;
        media = [post.media anyObject];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:media];        
    [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:media];
    
    appDelegate.isUploadingPost = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [media uploadWithSuccess:nil failure:nil];
        [post save];
    });
    
    [self dismiss];
    [sidebarViewController uploadQuickPhoto:post];
}

- (void)dismiss {
    if (IS_IPAD) {
        //TODO: Hmmm.... 
        [[self sidebarViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[self sidebarViewController] dismissModalViewControllerAnimated:YES];
    }
}

- (void)cancel {
    self.photo = nil;
    if (post != nil) {
        [post deletePostWithSuccess:nil failure:nil];
    }
    [self dismiss];
}


- (void)saveImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (self.sourceType == UIImagePickerControllerSourceTypeCamera)
            UIImageWriteToSavedPhotosAlbum(self.photo, nil, nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            Media *media;
            
            Blog *blog = self.blogSelector.activeBlog;
            if (post == nil) {
                post = [Post newDraftForBlog:blog];
            }
            
            if (post.media && [post.media count] > 0) {
                media = [post.media anyObject];
            } else {
                media = [Media newMediaForPost:post];
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
            }
            
            [media save];
            [media release];
            [postButtonItem setEnabled:YES];
        });
    });
}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (popController) {
        [popController dismissPopoverAnimated:YES];
    }
    
    self.photo = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    self.photoImageView.image = self.photo;
    
    if (![self isViewLoaded]) {
        // If we get a memory warning on the way here our view could have unloaded.
        // In order to prevet a crash we'll make sure its loaded before 
        // dismissing the modal. 
        [self loadView];
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
    
    [self.titleTextField becomeFirstResponder];
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

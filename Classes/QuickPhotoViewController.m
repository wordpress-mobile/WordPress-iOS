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
#import "BlogsViewController.h"

@implementation QuickPhotoViewController
@synthesize photoImageView;
@synthesize titleTextField;
@synthesize contentTextView;
@synthesize blogSelector;
@synthesize postButtonItem;
@synthesize photo;
@synthesize blogsViewController;
@synthesize sourceType;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.photoImageView.delegate = nil;
    self.photoImageView = nil;
    self.titleTextField = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;
    [super dealloc];
}

//stackoverflow.com/questions/945082/uiwebview-in-multithread-viewcontroller
- (oneway void)release
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    } else {
        [super release];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    self.titleTextField.placeholder = NSLocalizedString(@"Title (optional)", @"Quick Photo title");
    [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
    self.blogSelector.delegate = self;
    if (self.photo) {
        self.photoImageView.image = self.photo;
    }
    self.photoImageView.delegate = self;
    self.navigationItem.title = NSLocalizedString(@"Quick Photo", @"");
    self.postButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)] autorelease];
    [postButtonItem setEnabled:NO];
    self.navigationItem.rightBarButtonItem = self.postButtonItem;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void) saveImage{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIImageWriteToSavedPhotosAlbum(self.photo, nil, nil, nil);
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
    [pool release];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.photo == nil) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = self.sourceType;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        picker.allowsEditing = NO;
        picker.delegate = self;
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (void)viewDidUnload
{
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Custom methods

- (void)postInBackground {

    [post save];

}

- (void)post {
    Blog *blog = self.blogSelector.activeBlog;
    if (post == nil) {
        post = [Post newDraftForBlog:blog];
    } else {
        post.blog = blog;
        [[post.media anyObject] setBlog:blog];
    }
    post.postTitle = titleTextField.text;
    post.content = contentTextView.text;
    post.specialType = @"QuickPhoto";
    post.postFormat = @"image";

    [self performSelectorOnMainThread:@selector(postInBackground) withObject:nil waitUntilDone:YES];
    [self.navigationController popViewControllerAnimated:YES];
    [blogsViewController uploadQuickPhoto: post];
    
}

- (void)dismiss {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancel {
    self.photo = nil;
    if (post != nil) {
        [post removeWithError:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.photo = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    self.photoImageView.image = self.photo;
    
    [picker dismissModalViewControllerAnimated:NO];
    [self performSelectorInBackground:@selector(saveImage) withObject:nil];
    
    [self.titleTextField becomeFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    picker.delegate = nil;
    [picker dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
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

@end

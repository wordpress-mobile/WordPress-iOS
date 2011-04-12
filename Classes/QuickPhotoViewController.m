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

@implementation QuickPhotoViewController
@synthesize photoImageView;
@synthesize titleTextField;
@synthesize contentTextView;
@synthesize blogSelector;
@synthesize postButtonItem;
@synthesize photo;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.photoImageView.delegate = nil;
    self.photoImageView = nil;
    self.titleTextField = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;
    [spinner release]; spinner = nil;

    [super dealloc];
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
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentModalViewController:picker animated:YES];
    
    self.titleTextField.placeholder = NSLocalizedString(@"Title (optional)", @"Quick Picture title");
    [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
    self.blogSelector.delegate = self;
    if (self.photo) {
        self.photoImageView.image = self.photo;
    }
    self.photoImageView.delegate = self;
    spinner = [[WPProgressHUD alloc] initWithLabel:NSLocalizedString(@"Publishing...", @"")];
    self.navigationItem.title = NSLocalizedString(@"Quick Picture", @"");
    self.postButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)] autorelease];
    self.navigationItem.rightBarButtonItem = self.postButtonItem;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDidUploadSuccessfully:) name:@"PostUploaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUploadFailed:) name:@"PostUploadFailed" object:nil];
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
    [spinner release]; spinner = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Custom methods

- (void)postInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    UIImageWriteToSavedPhotosAlbum(self.photo, nil, nil, nil);
    Blog *blog = self.blogSelector.activeBlog;
    Media *media;
    if (post == nil) {
        post = [Post newDraftForBlog:blog];
    }
    post.postTitle = titleTextField.text;
    post.content = contentTextView.text;
    
    if (post.media && [post.media count] > 0) {
        media = [post.media anyObject];
    } else {
        media = [Media newMediaForPost:post];
        [media setImage:self.photo withSize:kResizeLarge];        
    }
    
    [spinner performSelectorOnMainThread:@selector(setTitle:) withObject:NSLocalizedString(@"Uploading picture...", @"") waitUntilDone:YES];
    [media performSelectorOnMainThread:@selector(upload) withObject:nil waitUntilDone:YES];

    [pool release];
}

- (void)post {
    [spinner show];
    [spinner setTitle:NSLocalizedString(@"Saving picture...", @"")];
    [self performSelectorInBackground:@selector(postInBackground) withObject:nil];
}

- (void)dismiss {
    [spinner dismiss];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
    Media *media = (Media *)[notification object];
    [media save];
    [spinner setTitle:NSLocalizedString(@"Publishing picture...", @"")];
    post.content = [NSString stringWithFormat:@"%@\n\n%@", [media html], post.content];
    [post upload];    
}

- (void)mediaUploadFailed:(NSNotification *)notification {
    [spinner dismiss];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Picture failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the picture upload failed", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)postDidUploadSuccessfully:(NSNotification *)notification {
    [spinner setTitle:@"Success"];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
}

- (void)postUploadFailed:(NSNotification *)notification {
    [spinner dismiss];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Picture failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the picture publish failed", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)cancel {
    self.photo = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.photo = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    self.photoImageView.image = self.photo;
    [picker dismissModalViewControllerAnimated:YES];
    [self.contentTextView becomeFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Blog selector delegate
- (void)blogSelectorButtonWillBecomeActive:(BlogSelectorButton *)button {
    [titleTextField resignFirstResponder];
    [contentTextView resignFirstResponder];
    [self.view bringSubviewToFront:button];
}

- (void)blogSelectorButtonDidBecomeInactive:(BlogSelectorButton *)button {
    [contentTextView becomeFirstResponder];
}

#pragma mark - Quick picture preview view delegate

- (void)pictureWillZoom {
    [titleTextField resignFirstResponder];
    [contentTextView resignFirstResponder];
    [self.view bringSubviewToFront:photoImageView];
}

- (void)pictureDidRestore {
    [contentTextView becomeFirstResponder];
}

@end

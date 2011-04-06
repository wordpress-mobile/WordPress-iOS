//
//  QuickPhotoViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "QuickPhotoViewController.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"

@implementation QuickPhotoViewController
@synthesize blavatarImageView, photoImageView;
@synthesize blogTitleLabel;
@synthesize contentTextView;
@synthesize postButtonItem;
@synthesize photo;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.blavatarImageView = nil;
    self.photoImageView = nil;
    self.blogTitleLabel = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;

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
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentModalViewController:picker animated:YES];
    
    NSString *blogId = [[NSUserDefaults standardUserDefaults] objectForKey:QPVCBlogForQuickPhoto];
    Blog *selectedBlog = nil;
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApp] managedObjectContext];
    NSPersistentStoreCoordinator *psc = [[WordPressAppDelegate sharedWordPressApp] persistentStoreCoordinator];
    NSError *error = nil;
    if (blogId != nil) {
        selectedBlog = (Blog *)[moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:blogId]] error:nil];
        if (selectedBlog == nil) {
            // The default blog was invalid, remove the stored default
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:QPVCBlogForQuickPhoto];
        }
    }
    if (selectedBlog == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]]];
        [fetchRequest setFetchLimit:1];
        NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
        if (results && ([results count] > 0)) {
            selectedBlog = [results objectAtIndex:0];
        }
    }
    blogTitleLabel.text = selectedBlog.blogName;
    blavatarImageView.isBlavatar = YES;
    blavatarImageView.isWPCOM = [selectedBlog isWPcom];
    [blavatarImageView loadImageFromURL:[selectedBlog blavatarURL]];
    if (self.photo) {
        self.photoImageView.image = self.photo;
    }
    self.navigationItem.title = NSLocalizedString(@"Quick Picture", @"");
    self.postButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)] autorelease];
    self.navigationItem.rightBarButtonItem = self.postButtonItem;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.blavatarImageView = nil;
    self.photoImageView = nil;
    self.blogTitleLabel = nil;
    self.contentTextView = nil;
    self.postButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)selectBlog {
    
}

- (void)post {
    
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

@end

#import "WPPhotoViewController.h"
#import "BlogDataManager.h"
#import "WPPhotosListViewController.h"
#import "PostViewController.h"
#import "WordPressAppDelegate.h"

@implementation WPPhotoViewController

@synthesize currentPhotoIndex, photosListViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //TODO : Need to remove the logic to call viewWillAppear. Has been placed to avoid crash on iPhone SDK 2.2
    [self viewWillAppear:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    id array = [photosListViewController.delegate photosDataSource];

    if ([array count] == 1) {
        previousImageButtonItem.enabled = NO;
        nextImageButtonItem.enabled = NO;
    } else if (currentPhotoIndex == 0) {
        previousImageButtonItem.enabled = NO;
    } else if (currentPhotoIndex ==[array count] - 1) {
        nextImageButtonItem.enabled = NO;
    } else {
        previousImageButtonItem.enabled = YES;
        nextImageButtonItem.enabled = YES;
    }

    titleButtonItem.title = [NSString stringWithFormat:@"%d of %d", currentPhotoIndex + 1, [array count]];
    imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    return YES;
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (IBAction)cancel:(id)sender {
    [[(UIViewController *)[photosListViewController delegate] navigationController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)previousImage:(id)sender {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    id array = [photosListViewController.delegate photosDataSource];

    if (--currentPhotoIndex <= 0)
        previousImageButtonItem.enabled = NO;

    if (currentPhotoIndex < ([array count] - 1))
        nextImageButtonItem.enabled = YES;

    titleButtonItem.title = [NSString stringWithFormat:@"%d of %d", currentPhotoIndex + 1, [array count]];
    imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
}

- (IBAction)nextImage:(id)sender {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    id array = [photosListViewController.delegate photosDataSource];

    if (++currentPhotoIndex >=[array count] - 1)
        nextImageButtonItem.enabled = NO;

    if (currentPhotoIndex > 0)
        previousImageButtonItem.enabled = YES;

    titleButtonItem.title = [NSString stringWithFormat:@"%d of %d", currentPhotoIndex + 1, [array count]];
    imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
}

- (IBAction)deleteImage:(id)sender {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    id array = [photosListViewController.delegate photosDataSource];
    [dataManager deleteImageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
    [array removeObjectAtIndex:currentPhotoIndex];

    if (currentPhotoIndex <[array count]) {
        if (currentPhotoIndex + 1 >=[array count])
            nextImageButtonItem.enabled = NO;

        imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
    } else if (currentPhotoIndex - 1 > -1)
        [self previousImage:nil];else {
        currentPhotoIndex = -1;
        trashImageButtonItem.enabled = NO;
        nextImageButtonItem.enabled = NO;
        imageView.image = nil;
        [self cancel:nil];
    }

    titleButtonItem.title = [NSString stringWithFormat:@"%d of %d", currentPhotoIndex + 1, [array count]];

    [photosListViewController.delegate updatePhotosBadge];
    [photosListViewController.delegate setHasChanges:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    previousImageButtonItem.enabled = YES;
    nextImageButtonItem.enabled = YES;
    trashImageButtonItem.enabled = YES;

    [photosListViewController.tableView reloadData];
}

- (void)dealloc {
    [super dealloc];
}

@end

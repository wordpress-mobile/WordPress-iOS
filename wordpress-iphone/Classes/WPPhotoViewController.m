#import "WPPhotoViewController.h"
#import "BlogDataManager.h"
#import "WPPhotosListViewController.h"
#import "PostDetailViewController.h"

@implementation WPPhotoViewController

@synthesize currentPhotoIndex, photosListViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */

- (void)viewWillAppear:(BOOL)animated {
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	id array = [dataManager.currentPost valueForKey:@"Photos"];
	if ([array count] == 1) {
		previousImageButtonItem.enabled = NO;
		nextImageButtonItem.enabled = NO;
	} else if (currentPhotoIndex == 0) {
		previousImageButtonItem.enabled = NO;
	} else if (currentPhotoIndex == [array count]-1) {
		nextImageButtonItem.enabled = NO;
	} else	{
		previousImageButtonItem.enabled = YES;
		nextImageButtonItem.enabled = YES;
	}
	titleButtonItem.title = [NSString stringWithFormat:@"%d of %d",currentPhotoIndex+1, [array count]];
	imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (IBAction)cancel:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)previousImage:(id)sender {
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	id array = [dataManager.currentPost valueForKey:@"Photos"];
	if (--currentPhotoIndex <= 0)
		previousImageButtonItem.enabled = NO;

	if (currentPhotoIndex < ([array count] - 1))
		nextImageButtonItem.enabled = YES;

//	NSLog(@"prev currentPhotoIndex %d",currentPhotoIndex);
	titleButtonItem.title = [NSString stringWithFormat:@"%d of %d",currentPhotoIndex+1, [array count]];
	imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
	
}

- (IBAction)nextImage:(id)sender {
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	id array = [dataManager.currentPost valueForKey:@"Photos"];
	
	if (++currentPhotoIndex >= [array count] - 1)
		nextImageButtonItem.enabled = NO;

	if (currentPhotoIndex > 0)
		previousImageButtonItem.enabled = YES;
	
//	NSLog(@"next currentPhotoIndex %d",currentPhotoIndex);
	titleButtonItem.title = [NSString stringWithFormat:@"%d of %d",currentPhotoIndex+1, [array count]];
	imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
	
}

- (IBAction)deleteImage:(id)sender {
//	NSLog(@"currentPhotoIndex %d",currentPhotoIndex);
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	id array = [dataManager.currentPost valueForKey:@"Photos"];
	[dataManager deleteImageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
	[array removeObjectAtIndex:currentPhotoIndex];

	if (currentPhotoIndex < [array count]) {

		if (currentPhotoIndex+1 >= [array count])
			nextImageButtonItem.enabled = NO;
			
		imageView.image = [dataManager imageNamed:[array objectAtIndex:currentPhotoIndex] forBlog:dataManager.currentBlog];
	}
	else if (currentPhotoIndex-1 > -1)
		[self previousImage:nil];
	else {
		currentPhotoIndex = -1;
		trashImageButtonItem.enabled = NO;
		nextImageButtonItem.enabled = NO;
		imageView.image = nil;
		[self cancel:nil];
	}
	titleButtonItem.title = [NSString stringWithFormat:@"%d of %d",currentPhotoIndex+1, [array count]];
	[photosListViewController.postDetailViewController updatePhotosBadge];
	photosListViewController.postDetailViewController.hasChanges = YES;
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

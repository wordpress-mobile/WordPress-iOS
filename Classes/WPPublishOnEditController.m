#import "WPPublishOnEditController.h"
#import "BlogDataManager.h"
#import "PostDetailViewController.h"
#import "WPPostSettingsController.h"

@implementation WPPublishOnEditController

@synthesize settingController;

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterFullStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	}
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	NSDate *today = [NSDate date];
	datePicker.date = [[dataManager currentPost] valueForKey:@"date_created_gmt"];
	datePicker.minimumDate = today;
	dateLabel.text = [dateFormatter stringFromDate:[[dataManager currentPost] valueForKey:@"date_created_gmt"]];
}

// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[settingController reloadData];
}

- (NSDate *)currentSelectedDate
{
	return datePicker.date;
}

-(IBAction)datePickerValueChanged:(id)sender {
	WPLog(@"datePickerValueChanged");
	
	[dateLabel setText:[dateFormatter stringFromDate:datePicker.date]];
	[[[BlogDataManager sharedDataManager] currentPost] setValue:datePicker.date forKey:@"date_created_gmt"];
//	[[[BlogDataManager sharedDataManager] currentPost] setValue:datePicker.date forKey:@"dateCreated"];
	settingController.postDetailViewController.hasChanges = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return NO;
}


- (void)didReceiveMemoryWarning {
		WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[dateFormatter release];
	[super dealloc];
}


@end

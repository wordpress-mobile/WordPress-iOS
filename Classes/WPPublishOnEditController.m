#import "WPPublishOnEditController.h"
#import "BlogDataManager.h"
#import "PostViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"

@implementation WPPublishOnEditController

@synthesize settingController;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }

    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    datePicker.date = [[dataManager currentPost] valueForKey:@"date_created_gmt"];
    dateLabel.text = [dateFormatter stringFromDate:[[dataManager currentPost] valueForKey:@"date_created_gmt"]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [settingController reloadData];
}

- (NSDate *)currentSelectedDate {
    return datePicker.date;
}

- (IBAction)datePickerValueChanged:(id)sender {
    [dateLabel setText:[dateFormatter stringFromDate:datePicker.date]];
    [[[BlogDataManager sharedDataManager] currentPost] setValue:datePicker.date forKey:@"date_created_gmt"];
//	[[[BlogDataManager sharedDataManager] currentPost] setValue:datePicker.date forKey:@"dateCreated"];
    settingController.postDetailViewController.hasChanges = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    // Return YES for supported orientations
	NSLog(@"inside WPPublishOnEditController : shouldAutorotateToInterfaceOrientation");
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	if (orientation == UIDeviceOrientationLandscapeRight)
	{
		NSLog(@"Landscape Right!");
	}
	if ((orientation == UIDeviceOrientationLandscapeRight) || 
		(orientation == UIDeviceOrientationLandscapeLeft)) {
			[self moveDatePickerUp];
	}else {
		if ((orientation == UIDeviceOrientationPortrait) || 
			(orientation == UIDeviceOrientationPortraitUpsideDown)) {
				[self moveDatePickerDown];
		}
	}
	return YES;
	//return NO; //see ticket #148
}

- (void) moveDatePickerUp {
			
NSLog(@"inside moveDatePickerUp");
[UIView beginAnimations:nil context:NULL];
			
CGRect frame = datePicker.frame;
frame.origin.y -= 73.0f;
datePicker.frame = frame;

[UIView commitAnimations];
NSLog(@"just tried to commit animations inside WPPublishOnEditController : moveDatePickerUp");
		}
		
		
		
- (void) moveDatePickerDown {
NSLog(@"inside moveDatePickerDown");
[UIView beginAnimations:nil context:NULL];
			
CGRect frame = datePicker.frame;
frame.origin.y += 73.0f;
datePicker.frame = frame;
			
[UIView commitAnimations];
NSLog(@"just tried to commit animations inside WPPublishOnEditController : moveDatePickerDown");
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

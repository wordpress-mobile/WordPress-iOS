#import "WPPublishOnEditController.h"
#import "BlogDataManager.h"
#import "EditPostViewController.h"
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

    //BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	if (settingController.postDetailViewController.post.dateCreated != nil){
		datePicker.date = settingController.postDetailViewController.post.dateCreated;
		dateLabel.text = [dateFormatter stringFromDate:settingController.postDetailViewController.post.dateCreated];
	}
	else {
		datePicker.date = [NSDate date];
	}
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
	settingController.postDetailViewController.post.dateCreated = datePicker.date;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}

    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    // Return YES for supported orientations

	//return YES;
	return NO; //see ticket #148.  Trouble with rotation on real device although code worked fine on simulator...
}

- (void) moveDatePickerUp {
	[UIView beginAnimations:nil context:NULL];
				
	CGRect frame = datePicker.frame;
	frame.origin.y -= 73.0f;
	datePicker.frame = frame;

	[UIView commitAnimations];
}
		
- (void) moveDatePickerDown {
	[UIView beginAnimations:nil context:NULL];
				
	CGRect frame = datePicker.frame;
	frame.origin.y += 73.0f;
	datePicker.frame = frame;
				
	[UIView commitAnimations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [dateFormatter release];
    [super dealloc];
}

@end

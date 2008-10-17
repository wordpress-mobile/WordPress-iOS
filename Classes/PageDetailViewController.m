#import "PageDetailViewController.h"
#import "BlogDataManager.h"

@implementation PageDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)refreshUIForCurrentPage
{
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *description = [dm.currentPage valueForKey:@"description"];
	
	if (!description || [description length] == 0 ) {
		textViewPlaceHolderField.hidden = NO;
		textView.text = @"";
	} else {
		textViewPlaceHolderField.hidden = YES;
		textView.text = description;
	}
	
	titleTextField.text = [dm.currentPage valueForKey:@"title"];
	
	NSString *status = [dm statusDescriptionForStatus:[dm.currentPage valueForKey:@"page_status"] fromBlog:dm.currentBlog];
	status = ( status == nil ? @"" : status );
	statusTextField.text = status ;
	
	NSArray *cats = [[dm currentPage] valueForKey:@"categories"];
	if( status )
		categoriesTextField.text = [cats componentsJoinedByString:@", "];
	else 
		categoriesTextField.text = @"";
}

- (void)viewWillAppear:(BOOL)animated {

	BlogDataManager *dm = [BlogDataManager sharedDataManager];

	self.title=[[dm currentPage] valueForKey:@"title"];
	[self refreshUIForCurrentPage];
	[titleTextField setEnabled:NO];
	[textView setEditable:NO];
	[super viewWillAppear:animated];
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	return NO;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return NO;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	categoriesTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	categoriesLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	
	titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	[contentView bringSubviewToFront:textView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark TextView & TextField Delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}
- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)dealloc 
{	
	[super dealloc];
}

@end


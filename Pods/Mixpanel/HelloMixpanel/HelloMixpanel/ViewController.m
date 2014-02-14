#import "Mixpanel.h"
#import "MPSurvey.h"
#import "MPNotification.h"
#import "UIColor+MPColor.h"

#import "ViewController.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl *genderControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *weaponControl;
@property (nonatomic, weak) IBOutlet UIImageView *fakeBackground;
@property (nonatomic, weak) IBOutlet UITextField *surveyIDField;
@property (nonatomic, weak) IBOutlet UITextField *notificationIDField;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UISegmentedControl *notificationTypeControl;

@property (nonatomic, copy) NSString *showNotificationType;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.showNotificationType = MPNotificationTypeTakeover;
    UIScrollView *strongScrollView = _scrollView;
    if (strongScrollView != nil) {
        strongScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        strongScrollView.contentSize = self.view.bounds.size;
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (IBAction)trackEvent:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    UISegmentedControl * strongWeaponControl = _weaponControl;
    UISegmentedControl * strongGenderControl = _genderControl;
    if (strongGenderControl != nil && strongWeaponControl != nil) {
        NSString *gender = [strongGenderControl titleForSegmentAtIndex:(NSUInteger)strongGenderControl.selectedSegmentIndex];
        NSString *weapon = [strongWeaponControl titleForSegmentAtIndex:(NSUInteger)strongWeaponControl.selectedSegmentIndex];
        [mixpanel track:@"Player Create" properties:@{@"gender": gender, @"weapon": weapon}];
    }
}

- (IBAction)setPeopleProperties:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    UISegmentedControl * strongWeaponControl = _weaponControl;
    UISegmentedControl * strongGenderControl = _genderControl;
    if (strongGenderControl != nil && strongWeaponControl != nil) {
        NSString *gender = [strongGenderControl titleForSegmentAtIndex:(NSUInteger)strongGenderControl.selectedSegmentIndex];
        NSString *weapon = [strongWeaponControl titleForSegmentAtIndex:(NSUInteger)strongWeaponControl.selectedSegmentIndex];

        [mixpanel.people set:@{@"gender": gender, @"weapon": weapon}];
        // Mixpanel People requires that you explicitly set a distinct ID for the current user. In this case,
        // we're using the automatically generated distinct ID from event tracking, based on the device's MAC address.
        // It is strongly recommended that you use the same distinct IDs for Mixpanel Engagement and Mixpanel People.
        // Note that the call to Mixpanel People identify: can come after properties have been set. We queue them until
        // identify: is called and flush them at that time. That way, you can set properties before a user is logged in
        // and identify them once you know their user ID.
        [mixpanel identify:mixpanel.distinctId];
    }
}

- (IBAction)setNotificationType:(id)sender
{
    NSArray *types = @[MPNotificationTypeTakeover, MPNotificationTypeMini];
    self.showNotificationType = types[self.notificationTypeControl.selectedSegmentIndex];
}

- (IBAction)showSurvey:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    UITextField *strongSurveyIDField = _surveyIDField;
    if (strongSurveyIDField != nil && [strongSurveyIDField.text length] > 0) {
        [mixpanel showSurveyWithID:(NSUInteger)([strongSurveyIDField.text integerValue])];
    } else {
        [mixpanel showSurvey];
    }

    [strongSurveyIDField resignFirstResponder];
}

- (IBAction)showNotif:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    UITextField *strongNotificationIDField = _notificationIDField;
    if (strongNotificationIDField != nil && [strongNotificationIDField.text length] > 0) {
        [mixpanel showNotificationWithID:(NSUInteger)strongNotificationIDField.text.integerValue];
    } else {
        [mixpanel showNotificationWithType:_showNotificationType];
    }
    [strongNotificationIDField resignFirstResponder];
}

- (IBAction)changeBackground
{
    UIImageView *strongFakeBackground = _fakeBackground;
    if (strongFakeBackground != nil && strongFakeBackground.image != nil) {
        strongFakeBackground.image = nil;
        strongFakeBackground.hidden = YES;
    } else {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImageView *strongFakeBackground = _fakeBackground;
    if (strongFakeBackground != nil) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        strongFakeBackground.image = image;
        strongFakeBackground.hidden = NO;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard
{
    UITextField *strongSurveyIDField = _surveyIDField;
    UITextField *strongNotificationIDField = _notificationIDField;

    [strongSurveyIDField resignFirstResponder];
    [strongNotificationIDField resignFirstResponder];
}

- (IBAction)changeColor
{
    FCColorPickerViewController *colorPicker = [[FCColorPickerViewController alloc]
                                                initWithNibName:@"FCColorPickerViewController"
                                                bundle:[NSBundle mainBundle]];
    colorPicker.color = [UIColor mp_applicationPrimaryColor];
    colorPicker.delegate = self;

    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker animated:YES completion:nil];
}

- (void)colorPickerViewController:(FCColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[UINavigationBar appearance] respondsToSelector:@selector(setBarTintColor:)]) {
        [[UINavigationBar appearance] setBarTintColor:color];
    } else if (self.navigationController != nil && self.navigationController.navigationBar != nil) {
        self.navigationController.navigationBar.tintColor = color;
    }
#else
    if (self.navigationController != nil && self.navigationController.navigationBar != nil) {
        self.navigationController.navigationBar.tintColor = color;
    }
#endif

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidCancel:(FCColorPickerViewController *)colorPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

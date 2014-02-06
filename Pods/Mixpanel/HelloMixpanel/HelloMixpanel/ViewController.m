//
// ViewController.m
// HelloMixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "Mixpanel.h"
#import "MPSurvey.h"

#import "ViewController.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, retain) IBOutlet UISegmentedControl *genderControl;
@property(nonatomic, retain) IBOutlet UISegmentedControl *weaponControl;
@property(nonatomic, retain) IBOutlet UIImageView *fakeBackground;
@property(nonatomic, retain) IBOutlet UITextField *surveyIDField;
@property(nonatomic, retain) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewController

- (void)dealloc
{
    self.genderControl = nil;
    self.weaponControl = nil;
    self.fakeBackground = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.contentSize = self.view.bounds.size;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (IBAction)trackEvent:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSString *gender = [self.genderControl titleForSegmentAtIndex:(NSUInteger)self.genderControl.selectedSegmentIndex];
    NSString *weapon = [self.weaponControl titleForSegmentAtIndex:(NSUInteger)self.weaponControl.selectedSegmentIndex];
    [mixpanel track:@"Player Create" properties:@{@"gender": gender, @"weapon": weapon}];
}

- (IBAction)setPeopleProperties:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSString *gender = [self.genderControl titleForSegmentAtIndex:(NSUInteger)self.genderControl.selectedSegmentIndex];
    NSString *weapon = [self.weaponControl titleForSegmentAtIndex:(NSUInteger)self.weaponControl.selectedSegmentIndex];
    [mixpanel.people set:@{@"gender": gender, @"weapon": weapon}];
    // Mixpanel People requires that you explicitly set a distinct ID for the current user. In this case,
    // we're using the automatically generated distinct ID from event tracking, based on the device's MAC address.
    // It is strongly recommended that you use the same distinct IDs for Mixpanel Engagement and Mixpanel People.
    // Note that the call to Mixpanel People identify: can come after properties have been set. We queue them until
    // identify: is called and flush them at that time. That way, you can set properties before a user is logged in
    // and identify them once you know their user ID.
    [mixpanel identify:mixpanel.distinctId];
}

- (IBAction)showSurvey:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if ([_surveyIDField.text length] > 0) {
        [mixpanel showSurveyWithID:(NSUInteger)([_surveyIDField.text integerValue])];

    } else {
        [mixpanel showSurvey];
    }
    [_surveyIDField resignFirstResponder];
}

- (IBAction)changeBackground
{
    if (_fakeBackground.image) {
        _fakeBackground.image = nil;
        _fakeBackground.hidden = YES;
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
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    _fakeBackground.image = image;
    _fakeBackground.hidden = NO;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dismissKeyboard
{
    [_surveyIDField resignFirstResponder];
}

@end

//
//  ShareViewController.m
//
//  Copyright 2012 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ShareViewController.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <QuartzCore/QuartzCore.h>

@interface ShareViewController() <GPPShareDelegate>
- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow;
- (void)layout;
- (void)placeView:(UIView *)view x:(CGFloat)x y:(CGFloat)y;
- (void)populateTextFields;
@end

@implementation ShareViewController

@synthesize callToActions = callToActions_;
@synthesize selectedCallToAction = selectedCallToAction_;
@synthesize callToActionPickerView = callToActionPickerView_;
@synthesize addContentDeepLinkSwitch = addContentDeepLinkSwitch_;
@synthesize contentDeepLinkDescription = contentDeepLinkDescription_;
@synthesize contentDeepLinkID = contentDeepLinkID_;
@synthesize contentDeepLinkTitle = contentDeepLinkTitle_;
@synthesize contentDeepLinkThumbnailURL = contentDeepLinkThumbnailURL_;
@synthesize sharePrefillText = sharePrefillText_;
@synthesize shareURL = shareURL_;
@synthesize shareStatus = shareStatus_;
@synthesize shareToolbar = shareToolbar_;
@synthesize shareScrollView = shareScrollView_;
@synthesize shareView = shareView_;
@synthesize addContentDeepLinkLabel = addContentDeepLinkLabel_;
@synthesize urlToShareLabel = urlToShareLabel_;
@synthesize prefillTextLabel = prefillTextLabel_;
@synthesize contentDeepLinkIDLabel = contentDeepLinkIDLabel_;
@synthesize contentDeepLinkTitleLabel = contentDeepLinkTitleLabel_;
@synthesize contentDeepLinkDescriptionLabel =
    contentDeepLinkDescriptionLabel_;
@synthesize contentDeepLinkThumbnailURLLabel =
    contentDeepLinkThumbnailURLLabel_;
@synthesize shareButton = shareButton_;
@synthesize urlForContentDeepLinkMetadataSwitch =
    urlForContentDeepLinkMetadataSwitch_;
@synthesize urlForContentDeepLinkMetadataLabel =
    urlForContentDeepLinkMetadataLabel_;
@synthesize addCallToActionButtonSwitch = addCallToActionButtonSwitch_;
@synthesize addCallToActionButtonLabel = addCallToActionButtonLabel_;

- (void)dealloc {
  [callToActions_ release];
  [selectedCallToAction_ release];
  [callToActionPickerView_ release];
  [addContentDeepLinkSwitch_ release];
  [contentDeepLinkID_ release];
  [contentDeepLinkTitle_ release];
  [contentDeepLinkDescription_ release];
  [contentDeepLinkThumbnailURL_ release];
  [sharePrefillText_ release];
  [shareURL_ release];
  [shareStatus_ release];
  [shareToolbar_ release];
  [shareScrollView_ release];
  [shareView_ release];
  [addContentDeepLinkLabel_ release];
  [urlToShareLabel_ release];
  [prefillTextLabel_ release];
  [contentDeepLinkIDLabel_ release];
  [contentDeepLinkTitleLabel_ release];
  [contentDeepLinkDescriptionLabel_ release];
  [contentDeepLinkThumbnailURLLabel_ release];
  [shareButton_ release];
  [urlForContentDeepLinkMetadataSwitch_ release];
  [urlForContentDeepLinkMetadataLabel_ release];
  [addCallToActionButtonSwitch_ release];
  [addCallToActionButtonLabel_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Set up Google+ share dialog.
  [GPPShare sharedInstance].delegate = self;

  [addCallToActionButtonSwitch_ setOn:NO];
  [addContentDeepLinkSwitch_ setOn:NO];
  if (![GPPSignIn sharedInstance].authentication ||
      ![[GPPSignIn sharedInstance].scopes containsObject:
          kGTLAuthScopePlusLogin]) {
    addCallToActionButtonLabel_.text = @"Sign in for call-to-action";
    addCallToActionButtonSwitch_.enabled = NO;
  }
  addCallToActionButtonLabel_.adjustsFontSizeToFitWidth = YES;

  self.callToActions = [NSArray arrayWithObjects:
      @"ACCEPT",
      @"ACCEPT_GIFT",
      @"ADD",
      @"ANSWER",
      @"ADD_TO_CALENDAR",
      @"APPLY",
      @"ASK",
      @"ATTACK",
      @"BEAT",
      @"BID",
      @"BOOK",
      @"BOOKMARK",
      @"BROWSE",
      @"BUY",
      @"CAPTURE",
      @"CHALLENGE",
      @"CHANGE",
      @"CHECKIN",
      @"CLICK_HERE",
      @"CLICK_ME",
      @"COLLECT",
      @"COMMENT",
      @"COMPARE",
      @"COMPLAIN",
      @"CONFIRM",
      @"CONNECT",
      @"CONTRIBUTE",
      @"COOK",
      @"CREATE",
      @"DEFEND",
      @"DINE",
      @"DISCOVER",
      @"DISCUSS",
      @"DONATE",
      @"DOWNLOAD",
      @"EARN",
      @"EAT",
      @"EXPLAIN",
      @"FOLLOW",
      @"GET",
      @"GIFT",
      @"GIVE",
      @"GO",
      @"HELP",
      @"IDENTIFY",
      @"INSTALL_APP",
      @"INTRODUCE",
      @"INVITE",
      @"JOIN",
      @"JOIN_ME",
      @"LEARN",
      @"LEARN_MORE",
      @"LISTEN",
      @"LOVE",
      @"MAKE",
      @"MATCH",
      @"OFFER",
      @"OPEN",
      @"OPEN_APP",
      @"OWN",
      @"PAY",
      @"PIN",
      @"PLAN",
      @"PLAY",
      @"RATE",
      @"READ",
      @"RECOMMEND",
      @"RECORD",
      @"REDEEM",
      @"REPLY",
      @"RESERVE",
      @"REVIEW",
      @"RSVP",
      @"SAVE",
      @"SAVE_OFFER",
      @"SELL",
      @"SEND",
      @"SHARE_X",
      @"SIGN_IN",
      @"SIGN_UP",
      @"START",
      @"ST0P",
      @"TEST",
      @"UPVOTE",
      @"VIEW",
      @"VIEW_ITEM",
      @"VIEW_PROFILE",
      @"VISIT",
      @"VOTE",
      @"WANT",
      @"WATCH",
      @"WRITE",
      nil
  ];
  self.selectedCallToAction = [callToActions_ objectAtIndex:0];
  self.callToActionPickerView = [[[UIPickerView alloc] init] autorelease];
  callToActionPickerView_.delegate = self;
  callToActionPickerView_.dataSource = self;
  [addCallToActionButtonSwitch_ addTarget:self
                                   action:@selector(addCallToActionSwitched)
                         forControlEvents:UIControlEventValueChanged];

  [self layout];
  [self populateTextFields];
  [super viewDidLoad];
}

- (void)viewDidUnload {
  [GPPShare sharedInstance].delegate = nil;
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];

  [self setAddContentDeepLinkSwitch:nil];
  [self setContentDeepLinkID:nil];
  [self setContentDeepLinkTitle:nil];
  [self setContentDeepLinkDescription:nil];
  [self setContentDeepLinkThumbnailURL:nil];
  [self setShareScrollView:nil];
  [self setShareView:nil];
  [self setShareToolbar:nil];
  [self setAddContentDeepLinkLabel:nil];
  [self setUrlToShareLabel:nil];
  [self setPrefillTextLabel:nil];
  [self setContentDeepLinkIDLabel:nil];
  [self setContentDeepLinkTitleLabel:nil];
  [self setContentDeepLinkDescriptionLabel:nil];
  [self setContentDeepLinkThumbnailURLLabel:nil];
  [self setShareButton:nil];
  [self setUrlForContentDeepLinkMetadataSwitch:nil];
  [self setUrlForContentDeepLinkMetadataLabel:nil];
  [self setAddCallToActionButtonSwitch:nil];
  [self setAddCallToActionButtonLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
  if ([[UIDevice currentDevice] userInterfaceIdiom]
      == UIUserInterfaceIdiomPad) {
    shareScrollView_.frame = self.view.frame;
  }
  [super viewWillAppear:animated];

  // Register for keyboard notifications while visible.
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillShow:)
             name:UIKeyboardWillShowNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  // Unregister for keyboard notifications while not visible.
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];

  [super viewWillDisappear:animated];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  activeField_ = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  activeField_ = nil;
}

#pragma mark - GPPShareDelegate

- (void)finishedSharing:(BOOL)shared {
  NSString *text = shared ? @"Success" : @"Canceled";
  shareStatus_.text = [NSString stringWithFormat:@"Status: %@", text];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
    didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self shareButton:nil];
  } else if (buttonIndex == 1) {
    shareStatus_.text = @"Status: Sharing...";
    MFMailComposeViewController *picker =
        [[[MFMailComposeViewController alloc] init] autorelease];
    picker.mailComposeDelegate = self;
    [picker setSubject:sharePrefillText_.text];
    [picker setMessageBody:shareURL_.text isHTML:NO];

    [self presentModalViewController:picker animated:YES];
  }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
  NSString *text;
  switch (result) {
    case MFMailComposeResultCancelled:
      text = @"Canceled";
      break;
    case MFMailComposeResultSaved:
      text = @"Saved";
      break;
    case MFMailComposeResultSent:
      text = @"Sent";
      break;
    case MFMailComposeResultFailed:
      text = @"Failed";
      break;
    default:
      text = @"Not sent";
      break;
  }
  shareStatus_.text = [NSString stringWithFormat:@"Status: %@", text];
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIKeyboard

- (void)keyboardWillShow:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:NO];
}

#pragma mark - IBActions

- (IBAction)shareButton:(id)sender {
  shareStatus_.text = @"Status: Sharing...";
  id<GPPShareBuilder> shareBuilder = [[GPPShare sharedInstance] shareDialog];

  NSString *inputURL = shareURL_.text;
  NSURL *urlToShare = [inputURL length] ? [NSURL URLWithString:inputURL] : nil;
  if (urlToShare) {
    [shareBuilder setURLToShare:urlToShare];
  }

  if ([contentDeepLinkID_ text]) {
    [shareBuilder setContentDeepLinkID:[contentDeepLinkID_ text]];
    NSString *title = [contentDeepLinkTitle_ text];
    NSString *description = [contentDeepLinkDescription_ text];
    if (title && description) {
      NSURL *thumbnailURL =
          [NSURL URLWithString:[contentDeepLinkThumbnailURL_ text]];
      [shareBuilder setTitle:title
                 description:description
                thumbnailURL:thumbnailURL];
    }
  }

  NSString *inputText = sharePrefillText_.text;
  NSString *text = [inputText length] ? inputText : nil;
  if (text) {
    [shareBuilder setPrefillText:text];
  }

  if ([addCallToActionButtonSwitch_ isOn]) {
    // Please replace the URL below with your own call-to-action button URL.
    NSURL *callToActionURL = [NSURL URLWithString:
        @"http://developers.google.com/+/mobile/ios/"];
    [shareBuilder setCallToActionButtonWithLabel:selectedCallToAction_
                                             URL:callToActionURL
                                      deepLinkID:@"call-to-action"];
  }

  if (![shareBuilder open]) {
    shareStatus_.text = @"Status: Error (see console).";
  }
}

- (IBAction)shareToolbar:(id)sender {
  UIActionSheet *actionSheet =
      [[[UIActionSheet alloc] initWithTitle:@"Share this post"
                                   delegate:self
                          cancelButtonTitle:@"Cancel"
                     destructiveButtonTitle:nil
                          otherButtonTitles:@"Google+", @"Email", nil]
          autorelease];
  [actionSheet showFromToolbar:shareToolbar_];
}

- (IBAction)urlForContentDeepLinkMetadataSwitchToggle:(id)sender {
  [self layout];
  [self populateTextFields];
}

- (IBAction)contentDeepLinkSwitchToggle:(id)sender {
  if (!addContentDeepLinkSwitch_.on) {
    [urlForContentDeepLinkMetadataSwitch_ setOn:YES];
  }
  [self layout];
  [self populateTextFields];
}

#pragma mark - Helper methods

- (void)placeView:(UIView *)view x:(CGFloat)x y:(CGFloat)y {
  CGSize frameSize = view.frame.size;
  view.frame = CGRectMake(x, y, frameSize.width, frameSize.height);
}

- (void)layout {
  CGFloat originX = 20.0;
  CGFloat originY = 10.0;
  CGFloat yPadding = 10.0;
  CGFloat currentY = originY;
  CGFloat middleX = 150;

  // Place the switch for adding call-to-action button.
  [self placeView:addCallToActionButtonLabel_ x:originX y:currentY];
  [self placeView:addCallToActionButtonSwitch_ x:middleX * 1.5 y:currentY];
  CGSize frameSize = addCallToActionButtonSwitch_.frame.size;
  currentY += frameSize.height + yPadding;

  // Place the switch for attaching content deep-link data.
  [self placeView:addContentDeepLinkLabel_ x:originX y:currentY];
  [self placeView:addContentDeepLinkSwitch_ x:middleX * 1.5 y:currentY];
  frameSize = addContentDeepLinkSwitch_.frame.size;
  currentY += frameSize.height + yPadding;

  // Place the switch for preview URL.
  if (addContentDeepLinkSwitch_.on) {
    [self placeView:urlForContentDeepLinkMetadataLabel_ x:originX y:currentY];
    [self placeView:urlForContentDeepLinkMetadataSwitch_
                  x:middleX * 1.5
                  y:currentY];
    frameSize = urlForContentDeepLinkMetadataSwitch_.frame.size;
    currentY += frameSize.height + yPadding;
    urlForContentDeepLinkMetadataSwitch_.hidden = NO;
    urlForContentDeepLinkMetadataLabel_.hidden = NO;
  } else {
    urlForContentDeepLinkMetadataSwitch_.hidden = YES;
    urlForContentDeepLinkMetadataLabel_.hidden = YES;
  }

  // Place the field for URL to share.
  if (urlForContentDeepLinkMetadataSwitch_.on) {
    [self placeView:urlToShareLabel_ x:originX y:currentY];
    frameSize = urlToShareLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;

    [self placeView:shareURL_ x:originX y:currentY];
    frameSize = shareURL_.frame.size;
    currentY += frameSize.height + yPadding;
    urlToShareLabel_.hidden = NO;
    shareURL_.hidden = NO;
  } else {
    urlToShareLabel_.hidden = YES;
    shareURL_.hidden = YES;
  }

  // Place the field for prefill text.
  [self placeView:prefillTextLabel_ x:originX y:currentY];
  frameSize = prefillTextLabel_.frame.size;
  currentY += frameSize.height + 0.5 * yPadding;
  [self placeView:sharePrefillText_ x:originX y:currentY];
  frameSize = sharePrefillText_.frame.size;
  currentY += frameSize.height + yPadding;

  // Place the content deep-link ID field.
  if (addContentDeepLinkSwitch_.on) {
    [self placeView:contentDeepLinkIDLabel_ x:originX y:currentY];
    frameSize = contentDeepLinkIDLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:contentDeepLinkID_ x:originX y:currentY];
    frameSize = contentDeepLinkID_.frame.size;
    currentY += frameSize.height + yPadding;
    contentDeepLinkIDLabel_.hidden = NO;
    contentDeepLinkID_.hidden = NO;
  } else {
    contentDeepLinkIDLabel_.hidden = YES;
    contentDeepLinkID_.hidden = YES;
  }

  // Place fields for content deep-link metadata.
  if (addContentDeepLinkSwitch_.on &&
      !urlForContentDeepLinkMetadataSwitch_.on) {
    [self placeView:contentDeepLinkTitleLabel_ x:originX y:currentY];
    frameSize = contentDeepLinkTitleLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:contentDeepLinkTitle_ x:originX y:currentY];
    frameSize = contentDeepLinkTitle_.frame.size;
    currentY += frameSize.height + yPadding;

    [self placeView:contentDeepLinkDescriptionLabel_ x:originX y:currentY];
    frameSize = contentDeepLinkDescriptionLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:contentDeepLinkDescription_ x:originX y:currentY];
    frameSize = contentDeepLinkDescription_.frame.size;
    currentY += frameSize.height + yPadding;

    [self placeView:contentDeepLinkThumbnailURLLabel_ x:originX y:currentY];
    frameSize = contentDeepLinkThumbnailURLLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:contentDeepLinkThumbnailURL_ x:originX y:currentY];
    frameSize = contentDeepLinkThumbnailURL_.frame.size;
    currentY += frameSize.height + yPadding;

    contentDeepLinkTitle_.hidden = NO;
    contentDeepLinkTitleLabel_.hidden = NO;
    contentDeepLinkDescriptionLabel_.hidden = NO;
    contentDeepLinkDescription_.hidden = NO;
    contentDeepLinkThumbnailURLLabel_.hidden = NO;
    contentDeepLinkThumbnailURL_.hidden = NO;
  } else {
    contentDeepLinkTitle_.hidden = YES;
    contentDeepLinkTitleLabel_.hidden = YES;
    contentDeepLinkDescriptionLabel_.hidden = YES;
    contentDeepLinkDescription_.hidden = YES;
    contentDeepLinkThumbnailURLLabel_.hidden = YES;
    contentDeepLinkThumbnailURL_.hidden = YES;
  }

  // Place the share button and status.
  [[shareButton_ layer] setCornerRadius:5];
  [[shareButton_ layer] setMasksToBounds:YES];
  CGColorRef borderColor = [[UIColor colorWithWhite:203.0/255.0
                                              alpha:1.0] CGColor];
  [[shareButton_ layer] setBorderColor:borderColor];
  [[shareButton_ layer] setBorderWidth:1.0];

  [self placeView:shareButton_ x:originX y:currentY + yPadding];
  frameSize = shareButton_.frame.size;
  currentY += frameSize.height + yPadding * 2;

  [self placeView:shareStatus_ x:originX y:currentY];
  frameSize = shareStatus_.frame.size;
  currentY += frameSize.height + yPadding;

  shareScrollView_.contentSize =
      CGSizeMake(shareScrollView_.frame.size.width, currentY);
}

- (void)populateTextFields {
  // Pre-populate text fields for Google+ share sample.
  if (sharePrefillText_.hidden) {
    sharePrefillText_.text = @"";
  } else {
    sharePrefillText_.text = @"Welcome to Google+ Platform";
  }

  if (shareURL_.hidden) {
    shareURL_.text = @"";
  } else {
    shareURL_.text = @"http://developers.google.com/+/mobile/ios/";
  }

  if (contentDeepLinkID_.hidden) {
    contentDeepLinkID_.text = @"";
  } else {
    contentDeepLinkID_.text = @"playlist/314159265358";
  }

  if (contentDeepLinkTitle_.hidden) {
    contentDeepLinkTitle_.text = @"";
  } else {
    contentDeepLinkTitle_.text = @"Joe's Pop Music Playlist";
  }

  if (contentDeepLinkDescription_.hidden) {
    contentDeepLinkDescription_.text = @"";
  } else {
    contentDeepLinkDescription_.text =
        @"Check out this playlist of my favorite pop songs!";
  }

  if (contentDeepLinkThumbnailURL_.hidden) {
    contentDeepLinkThumbnailURL_.text = @"";
  } else {
    contentDeepLinkThumbnailURL_.text =
        @"http://www.google.com/logos/2012/childrensday-2012-hp.jpg";
  }
}

- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow {
  if (!shouldShow) {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    shareScrollView_.contentInset = contentInsets;
    shareScrollView_.scrollIndicatorInsets = contentInsets;
    return;
  }

  NSDictionary *userInfo = [notification userInfo];
  CGRect kbFrame =
      [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
  CGSize kbSize = kbFrame.size;
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  shareScrollView_.contentInset = contentInsets;
  shareScrollView_.scrollIndicatorInsets = contentInsets;

  // If active text field is hidden by keyboard, scroll so it's visible.
  CGRect aRect = self.view.frame;
  aRect.size.height -= kbSize.height;
  CGPoint bottomLeft =
      CGPointMake(0.0, activeField_.frame.origin.y +
          activeField_.frame.size.height + 10);
  if (!CGRectContainsPoint(aRect, bottomLeft)) {
    CGPoint scrollPoint = CGPointMake(0.0, bottomLeft.y - aRect.size.height);
    [shareScrollView_ setContentOffset:scrollPoint animated:YES];
  }
  return;
}

- (void)addCallToActionSwitched {
  if (!addCallToActionButtonSwitch_.on) {
    return;
  }
  [self.view addSubview:callToActionPickerView_];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(NSInteger)component {
  return callToActions_.count;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
    forComponent:(NSInteger)component reusingView:(UIView *)view {
  UITableViewCell *cell = (UITableViewCell *)view;
  if (cell == nil) {
    cell = [[[UITableViewCell alloc]
          initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:nil] autorelease];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setBounds: CGRectMake(0, 0, cell.frame.size.width - 20 , 44)];
    UITapGestureRecognizer *singleTapGestureRecognizer =
        [[[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(toggleSelection:)] autorelease];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [cell addGestureRecognizer:singleTapGestureRecognizer];
  }
  NSString *callToAction = [callToActions_ objectAtIndex:row];
  if ([selectedCallToAction_ isEqualToString:callToAction]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  cell.textLabel.text = callToAction;
  cell.textLabel.font = [UIFont systemFontOfSize:12];
  cell.tag = row;
  return cell;
}

- (void)toggleSelection:(UITapGestureRecognizer *)recognizer {
  int row = recognizer.view.tag;
  self.selectedCallToAction = [callToActions_ objectAtIndex:row];
  [callToActionPickerView_ removeFromSuperview];
  // Force refresh checked/unchecked marks.
  [callToActionPickerView_ reloadAllComponents];
  addCallToActionButtonLabel_.text =
      [NSString stringWithFormat:@"Call-to-Action: %@", selectedCallToAction_];
}

@end

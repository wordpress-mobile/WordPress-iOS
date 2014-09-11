//
//  SignInViewController.m
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

#import "AuthInspectorViewController.h"
#import "DataPickerState.h"
#import "DataPickerViewController.h"
#import "SignInViewController.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <QuartzCore/QuartzCore.h>

typedef void(^AlertViewActionBlock)(void);

@interface SignInViewController () <GPPSignInDelegate>

@property (nonatomic, copy) void (^confirmActionBlock)(void);
@property (nonatomic, copy) void (^cancelActionBlock)(void);

@end

static NSString *const kPlaceholderUserName = @"<Name>";
static NSString *const kPlaceholderEmailAddress = @"<Email>";
static NSString *const kPlaceholderAvatarImageName = @"PlaceholderAvatar.png";

// Labels for the cells that have in-cell control elements.
static NSString *const kGetUserIDCellLabel = @"Get user ID";
static NSString *const kSingleSignOnCellLabel = @"Use Single Sign-On";
static NSString *const kButtonWidthCellLabel = @"Width";

// Labels for the cells that drill down to data pickers.
static NSString *const kColorSchemeCellLabel = @"Color scheme";
static NSString *const kStyleCellLabel = @"Style";
static NSString *const kAppActivitiesCellLabel = @"App activity types";

// Strings for Alert Views.
static NSString *const kSignOutAlertViewTitle = @"Warning";
static NSString *const kSignOutAlertViewMessage =
    @"Modifying this element will sign you out of G+. Are you sure you wish to continue?";
static NSString *const kSignOutAlertCancelTitle = @"Cancel";
static NSString *const kSignOutAlertConfirmTitle = @"Continue";

// Accessibility Identifiers.
static NSString *const kCredentialsButtonAccessibilityIdentifier = @"Credentials";

@implementation SignInViewController {
  // This is an array of arrays, each one corresponding to the cell
  // labels for its respective section.
  NSArray *_sectionCellLabels;

  // These sets contain the labels corresponding to cells that have various
  // types (each cell either drills down to another table view, contains an
  // in-cell switch, or contains a slider).
  NSArray *_drillDownCells;
  NSArray *_switchCells;
  NSArray *_sliderCells;

  // States storing the current set of selected elements for each data picker.
  DataPickerState *_colorSchemeState;
  DataPickerState *_styleState;
  DataPickerState *_appActivitiesState;

  // Map that keeps track of which cell corresponds to which DataPickerState.
  NSDictionary *_drilldownCellState;
}

#pragma mark - View lifecycle

- (void)gppInit {
  _sectionCellLabels = @[
    @[ kColorSchemeCellLabel, kStyleCellLabel, kButtonWidthCellLabel ],
    @[ kAppActivitiesCellLabel, kGetUserIDCellLabel, kSingleSignOnCellLabel ]
  ];

  // Groupings of cell types.
  _drillDownCells = @[
    kColorSchemeCellLabel,
    kStyleCellLabel,
    kAppActivitiesCellLabel
  ];

  _switchCells = @[ kGetUserIDCellLabel, kSingleSignOnCellLabel ];
  _sliderCells = @[ kButtonWidthCellLabel ];

  // Initialize data picker states.
  NSString *dictionaryPath =
      [[NSBundle mainBundle] pathForResource:@"DataPickerDictionary"
                                      ofType:@"plist"];
  NSDictionary *configOptionsDict =
      [NSDictionary dictionaryWithContentsOfFile:dictionaryPath];

  NSDictionary *colorSchemeDict =
      [configOptionsDict objectForKey:kColorSchemeCellLabel];
  NSDictionary *styleDict = [configOptionsDict objectForKey:kStyleCellLabel];
  NSDictionary *appActivitiesDict =
      [configOptionsDict objectForKey:kAppActivitiesCellLabel];

  _colorSchemeState =
      [[DataPickerState alloc] initWithDictionary:colorSchemeDict];
  _styleState = [[DataPickerState alloc] initWithDictionary:styleDict];
  _appActivitiesState =
      [[DataPickerState alloc] initWithDictionary:appActivitiesDict];

  _drilldownCellState = @{
    kColorSchemeCellLabel :   _colorSchemeState,
    kStyleCellLabel :         _styleState,
    kAppActivitiesCellLabel : _appActivitiesState
  };

  // Make sure the GPPSignInButton class is linked in because references from
  // xib file doesn't count.
  [GPPSignInButton class];

  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  signIn.shouldFetchGooglePlusUser = YES;
  signIn.shouldFetchGoogleUserEmail = YES;

  // Sync the current sign-in configurations to match the selected
  // app activities in the app activity picker.
  if (signIn.actions) {
    [_appActivitiesState.selectedCells removeAllObjects];

    for (NSString *appActivity in signIn.actions) {
      [_appActivitiesState.selectedCells
          addObject:[appActivity lastPathComponent]];
    }
  }

  signIn.delegate = self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self gppInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self gppInit];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.credentialsButton.accessibilityIdentifier = kCredentialsButtonAccessibilityIdentifier;
}

- (void)viewWillAppear:(BOOL)animated {
  [self adoptUserSettings];
  [[GPPSignIn sharedInstance] trySilentAuthentication];
  [self reportAuthStatus];
  [self updateButtons];
  [self.tableView reloadData];

  [super viewWillAppear:animated];
}

#pragma mark - GPPSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  if (error) {
    _signInAuthStatus.text =
        [NSString stringWithFormat:@"Status: Authentication error: %@", error];
    return;
  }
  [self reportAuthStatus];
  [self updateButtons];
}

- (void)didDisconnectWithError:(NSError *)error {
  if (error) {
    _signInAuthStatus.text =
        [NSString stringWithFormat:@"Status: Failed to disconnect: %@", error];
  } else {
    _signInAuthStatus.text =
        [NSString stringWithFormat:@"Status: Disconnected"];
  }
  [self refreshUserInfo];
  [self updateButtons];
}

- (void)presentSignInViewController:(UIViewController *)viewController {
  [[self navigationController] pushViewController:viewController animated:YES];
}

#pragma mark - Helper methods

// Updates the GPPSignIn shared instance and the GPPSignInButton
// to reflect the configuration settings that the user set
- (void)adoptUserSettings {
  GPPSignIn *signIn = [GPPSignIn sharedInstance];

  // There should only be one selected color scheme
  for (NSString *scheme in _colorSchemeState.selectedCells) {
    if ([scheme isEqualToString:@"Light"]) {
      _signInButton.colorScheme = kGPPSignInButtonColorSchemeLight;
    } else {
      _signInButton.colorScheme = kGPPSignInButtonColorSchemeDark;
    }
  }

  // There should only be one selected style
  for (NSString *style in _styleState.selectedCells) {
    GPPSignInButtonStyle newStyle;
    if ([style isEqualToString:@"Standard"]) {
      newStyle = kGPPSignInButtonStyleStandard;
      self.signInButtonWidthSlider.enabled = YES;
    } else if ([style isEqualToString:@"Wide"]) {
      newStyle = kGPPSignInButtonStyleWide;
      self.signInButtonWidthSlider.enabled = YES;
    } else {
      newStyle = kGPPSignInButtonStyleIconOnly;
      self.signInButtonWidthSlider.enabled = NO;
    }
    if (self.signInButton.style != newStyle) {
      self.signInButton.style = newStyle;
      self.signInButtonWidthSlider.minimumValue = [self minimumButtonWidth];
    }
    self.signInButtonWidthSlider.value = _signInButton.frame.size.width;
  }

  // There may be multiple app activity types supported
  NSMutableArray *supportedAppActivities = [[NSMutableArray alloc] init];
  for (NSString *appActivity in _appActivitiesState.selectedCells) {
    NSString *schema =
        [NSString stringWithFormat:@"http://schemas.google.com/%@",
                                   appActivity];
    [supportedAppActivities addObject:schema];
  }
  signIn.actions = supportedAppActivities;
}

// Temporarily force the sign in button to adopt its minimum allowed frame
// so that we can find out its minimum allowed width (used for setting the
// range of the width slider).
- (CGFloat)minimumButtonWidth {
  CGRect frame = self.signInButton.frame;
  self.signInButton.frame = CGRectZero;

  CGFloat minimumWidth = self.signInButton.frame.size.width;
  self.signInButton.frame = frame;

  return minimumWidth;
}

- (void)reportAuthStatus {
  if ([GPPSignIn sharedInstance].authentication) {
    _signInAuthStatus.text = @"Status: Authenticated";
  } else {
    // To authenticate, use Google+ sign-in button.
    _signInAuthStatus.text = @"Status: Not authenticated";
  }
  [self refreshUserInfo];
}

// Update the interface elements containing user data to reflect the
// currently signed in user.
- (void)refreshUserInfo {
  if ([GPPSignIn sharedInstance].authentication == nil) {
    self.userName.text = kPlaceholderUserName;
    self.userEmailAddress.text = kPlaceholderEmailAddress;
    self.userAvatar.image = [UIImage imageNamed:kPlaceholderAvatarImageName];
    return;
  }

  self.userEmailAddress.text = [GPPSignIn sharedInstance].userEmail;

  // The googlePlusUser member will be populated only if the appropriate
  // scope is set when signing in.
  GTLPlusPerson *person = [GPPSignIn sharedInstance].googlePlusUser;
  if (person == nil) {
    return;
  }

  self.userName.text = person.displayName;

  // Load avatar image asynchronously, in background
  dispatch_queue_t backgroundQueue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  dispatch_async(backgroundQueue, ^{
    NSData *avatarData = nil;
    NSString *imageURLString = person.image.url;
    if (imageURLString) {
      NSURL *imageURL = [NSURL URLWithString:imageURLString];
      avatarData = [NSData dataWithContentsOfURL:imageURL];
    }

    if (avatarData) {
      // Update UI from the main thread when available
      dispatch_async(dispatch_get_main_queue(), ^{
          self.userAvatar.image = [UIImage imageWithData:avatarData];
      });
    }
  });
}

// Adjusts "Sign in", "Sign out", and "Disconnect" buttons to reflect
// the current sign-in state (ie, the "Sign in" button becomes disabled
// when a user is already signed in).
- (void)updateButtons {
  BOOL authenticated = ([GPPSignIn sharedInstance].authentication != nil);

  self.signInButton.enabled = !authenticated;
  self.signOutButton.enabled = authenticated;
  self.disconnectButton.enabled = authenticated;
  self.credentialsButton.hidden = !authenticated;

  if (authenticated) {
    self.signInButton.alpha = 0.5;
    self.signOutButton.alpha = self.disconnectButton.alpha = 1.0;
  } else {
    self.signInButton.alpha = 1.0;
    self.signOutButton.alpha = self.disconnectButton.alpha = 0.5;
  }
}

// Creates and shows an UIAlertView asking the user to confirm their action as it will log them
// out of their current G+ session

- (void)showSignOutAlertViewWithConfirmationBlock:(void (^)(void))confirmationBlock
                                      cancelBlock:(void (^)(void))cancelBlock {
  if ([[GPPSignIn sharedInstance] authentication]) {
    self.confirmActionBlock = confirmationBlock;
    self.cancelActionBlock = cancelBlock;

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:kSignOutAlertViewTitle
                                                        message:kSignOutAlertViewMessage
                                                       delegate:self
                                              cancelButtonTitle:kSignOutAlertCancelTitle
                                              otherButtonTitles:kSignOutAlertConfirmTitle, nil];
    [alertView show];
  }
}

#pragma mark - IBActions

- (IBAction)signOut:(id)sender {
  [[GPPSignIn sharedInstance] signOut];
  [self reportAuthStatus];
  [self updateButtons];
}

- (IBAction)disconnect:(id)sender {
  [[GPPSignIn sharedInstance] disconnect];
}

- (IBAction)showAuthInspector:(id)sender {
  AuthInspectorViewController *authInspector =
  [[AuthInspectorViewController alloc] init];
  [[self navigationController] pushViewController:authInspector animated:YES];
}

- (void)toggleUserID:(UISwitch *)sender {
  if ([[GPPSignIn sharedInstance] authentication]) {
    [self showSignOutAlertViewWithConfirmationBlock:^(void) {
      [GPPSignIn sharedInstance].shouldFetchGoogleUserID = sender.on;
    }
                                        cancelBlock:^(void) {
                                          [sender setOn:!sender.on animated:YES];
                                        }];
  } else {
    [GPPSignIn sharedInstance].shouldFetchGoogleUserID = sender.on;
  }
}

- (void)toggleSingleSignOn:(UISwitch *)sender {
  [GPPSignIn sharedInstance].attemptSSO = sender.on;
}

- (void)changeSignInButtonWidth:(UISlider *)sender {
  CGRect frame = self.signInButton.frame;
  frame.size.width = sender.value;
  self.signInButton.frame = frame;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) {
    if (_cancelActionBlock) {
      _cancelActionBlock();
    }
  } else {
    if (_confirmActionBlock) {
      _confirmActionBlock();
      [self refreshUserInfo];
      [self updateButtons];
    }
  }

  _cancelActionBlock = nil;
  _confirmActionBlock = nil;
}

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_sectionCellLabels count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [_sectionCellLabels[section] count];
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return @"Sign-in Button Configuration";
  } else if (section == 1) {
    return @"Other Configurations";
  } else {
    return nil;
  }
}

- (BOOL)tableView:(UITableView *)tableView
    shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  // Cells that drill down to other table views should be highlight-able.
  // The other cells contain control elements, so they should not be selectable.
  NSString *label = _sectionCellLabels[indexPath.section][indexPath.row];
  if ([_drillDownCells containsObject:label]) {
    return YES;
  } else {
    return NO;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kDrilldownCell = @"DrilldownCell";
  static NSString * const kSwitchCell = @"SwitchCell";
  static NSString * const kSliderCell = @"SliderCell";

  NSString *label = _sectionCellLabels[indexPath.section][indexPath.row];
  UITableViewCell *cell;
  NSString *identifier;

  if ([_drillDownCells containsObject:label]) {
    identifier = kDrilldownCell;
  } else if ([_switchCells containsObject:label]) {
    identifier = kSwitchCell;
  } else if ([_sliderCells containsObject:label]) {
    identifier = kSliderCell;
  }

  cell = [tableView dequeueReusableCellWithIdentifier:identifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                  reuseIdentifier:identifier];
  }
  // Assign accessibility labels to each cell row.
  cell.accessibilityLabel = label;

  if (identifier == kDrilldownCell) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    DataPickerState *dataState = _drilldownCellState[label];
    if (dataState.multipleSelectEnabled) {
      cell.detailTextLabel.text = @"";
    } else {
      cell.detailTextLabel.text = [dataState.selectedCells anyObject];
    }
    cell.accessibilityValue = cell.detailTextLabel.text;
  } else if (identifier == kSwitchCell) {
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];

    if ([label isEqualToString:kGetUserIDCellLabel]) {
      [toggle addTarget:self
                 action:@selector(toggleUserID:)
          forControlEvents:UIControlEventValueChanged];
      toggle.on = [GPPSignIn sharedInstance].shouldFetchGoogleUserID;
    } else if ([label isEqualToString:kSingleSignOnCellLabel]) {
      [toggle addTarget:self
                 action:@selector(toggleSingleSignOn:)
          forControlEvents:UIControlEventValueChanged];
      toggle.on = [GPPSignIn sharedInstance].attemptSSO;
    }
    toggle.accessibilityLabel = [NSString stringWithFormat:@"%@ Switch", cell.accessibilityLabel];
    cell.accessoryView = toggle;
  } else if (identifier == kSliderCell) {
    UISlider *slider =
        [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 150, 0)];
    slider.minimumValue = [self minimumButtonWidth];
    slider.maximumValue = 268.0;
    slider.value = self.signInButton.frame.size.width;
    slider.enabled = self.signInButton.style != kGPPSignInButtonStyleIconOnly;

    [slider addTarget:self
               action:@selector(changeSignInButtonWidth:)
        forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = slider;
    slider.accessibilityIdentifier = [NSString stringWithFormat:@"%@ Slider", label];
    self.signInButtonWidthSlider = slider;
  }

  cell.textLabel.text = label;
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *label = selectedCell.textLabel.text;

  DataPickerState *dataState = [_drilldownCellState objectForKey:label];
  if (!dataState) {
    return;
  }

  DataPickerViewController *dataPicker =
      [[DataPickerViewController alloc] initWithNibName:nil
                                                 bundle:nil
                                              dataState:dataState];
  dataPicker.navigationItem.title = label;

  // Force the back button title to be 'Back'
  UIBarButtonItem *newBackButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                       style:UIBarButtonItemStyleBordered
                                      target:nil
                                      action:nil];
  [[self navigationItem] setBackBarButtonItem:newBackButton];

  if ([[GPPSignIn sharedInstance] authentication] &&
      [label isEqualToString:kAppActivitiesCellLabel]) {
    [self showSignOutAlertViewWithConfirmationBlock:^(void) {
      [self.navigationController pushViewController:dataPicker animated:YES];
    }
                                        cancelBlock:nil];
  } else {
    [self.navigationController pushViewController:dataPicker animated:YES];
  }
}

@end

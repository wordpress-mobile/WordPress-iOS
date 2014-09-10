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

#import "DataPickerState.h"
#import "DataPickerViewController.h"
#import "EditableCell.h"
#import "ListPeopleViewController.h"
#import "ShareActivity.h"
#import "ShareBundleMediaPickerController.h"
#import "ShareConfiguration.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

typedef enum {
  kShareOptionsSection,
  kURLSection,
  kDeepLinkSection,
  kCallToActionSection,
  kMediaSection
} SectionOrdering;

static NSString * const kCellTypeEditable = @"editable";
static NSString * const kCellTypeSwitch = @"switch";
static NSString * const kCellTypeDrilldown = @"drilldown";

static NSString * const kAddURLLabel = @"Add URL attachment";
static NSString * const kAddCallToActionLabel = @"Add call-to-action";
static NSString * const kAddDeepLinkLabel = @"Add deep link";
static NSString * const kAddMediaLabel = @"Add media";

static NSString * const kPrefillAudiencesDrilldownLabel = @"Pre-fill audiences";
static NSString * const kCallToActionLabelDrilldownLabel = @"Label";
static NSString * const kAttachAssetFromLibraryDrilldownLabel = @"Attach asset from library";
static NSString * const kAttachAssetFromBundleDrilldownLabel = @"Attach asset from bundle";

@interface ShareViewController () <
    GPPShareDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    ShareBundleMediaPickerControllerDelegate,
    ListPeopleViewControllerDelegate>

@end

@implementation ShareViewController {
  // Keeps track of the current user settings for sharing.
  ShareConfiguration *_shareConfiguration;
  // The popover shown when accessing the Asset Library on the iPad
  UIPopoverController *_assetLibraryPopover;
}

- (void)gppInit {
  _shareConfiguration = [ShareConfiguration sharedInstance];

  [GPPShare sharedInstance].delegate = self;
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
  // Configure share button graphics.
  [[_shareButton layer] setCornerRadius:5];
  [[_shareButton layer] setMasksToBounds:YES];
  UIColor *borderColor = [UIColor colorWithWhite:203.0f/255.0f
                                           alpha:1.0];
  [[_shareButton layer] setBorderColor:[borderColor CGColor]];
  [[_shareButton layer] setBorderWidth:1.0];

  // The right bar button item launches the share sheet, which includes
  // a G+ share icon.
  UIBarButtonItem *rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                    target:self
                                                    action:@selector(shareSheetButton:)];
  rightBarButtonItem.accessibilityLabel = @"share_sheet_button";
  self.navigationItem.rightBarButtonItem = rightBarButtonItem;

  // If we are not logged in, then call-to-action is disabled.
  if (![GPPSignIn sharedInstance].authentication ||
      ![[GPPSignIn sharedInstance].scopes containsObject:
          kGTLAuthScopePlusLogin]) {
    _shareConfiguration.callToActionEnabled = NO;
    _useNativeSharebox.on = NO;
    _useNativeSharebox.enabled = NO;
    _shareConfiguration.useNativeSharebox = NO;
    _nativeShareboxLabel.text = @"Sign in to use native sharebox";
  } else {
    _useNativeSharebox.on = YES;
    _useNativeSharebox.enabled = YES;
    _shareConfiguration.useNativeSharebox = YES;
    _nativeShareboxLabel.text = @"Use native sharebox";
  }

  [super viewDidLoad];
}

#pragma mark - GPPShareDelegate

- (void)finishedSharingWithError:(NSError *)error {
  NSString *text;
  if (!error) {
    text = @"Success";
  } else if (error.code == kGPPErrorShareboxCanceled) {
    text = @"Canceled";
  } else {
    text = [NSString stringWithFormat:@"Error (%@)", [error localizedDescription]];
  }
  _shareStatus.text = [NSString stringWithFormat:@"Status: %@", text];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_shareConfiguration numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  // If call-to-action/deep-link/media attachment/URL sections are not enabled, then
  // they both only have one row (to contain the enable cell).
  if (section == kCallToActionSection && !_shareConfiguration.callToActionEnabled) {
    return 1;
  } else if (section == kDeepLinkSection && !_shareConfiguration.deepLinkEnabled) {
    return 1;
  } else if (section == kMediaSection && !_shareConfiguration.mediaAttachmentEnabled) {
    return 1;
  } else if (section == kURLSection && !_shareConfiguration.urlEnabled) {
    return 1;
  } else {
    return [_shareConfiguration numberOfCellsInSection:section];
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  NSString *headerTitle = [_shareConfiguration titleForSection:section];

  if (section == kCallToActionSection) {
    if (![GPPSignIn sharedInstance].authentication ||
        ![[GPPSignIn sharedInstance].scopes containsObject:
            kGTLAuthScopePlusLogin]) {
      return [headerTitle stringByAppendingString:@" (Sign in to enable)"];
    }
  } else if (section == kMediaSection) {
    return [headerTitle stringByAppendingString:@" (native sharebox)"];
  }

  return headerTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *label = [_shareConfiguration labelForCellAtIndexPath:indexPath];
  NSString *type = [_shareConfiguration typeForCellAtIndexPath:indexPath];

  UITableViewCell *cell;
  if ([type isEqualToString:kCellTypeEditable]) {
    cell = [self editableCellForTableView:tableView indexPath:indexPath];
  } else if ([type isEqualToString:kCellTypeSwitch]) {
    cell = [self switchCellForTableView:tableView indexPath:indexPath];
  } else if ([type isEqualToString:kCellTypeDrilldown]) {
    cell = [self drilldownCellForTableView:tableView indexPath:indexPath];
  }

  if ([label isEqualToString:kPrefillAudiencesDrilldownLabel]) {
    if (![GPPSignIn sharedInstance].authentication ||
        ![[GPPSignIn sharedInstance].scopes containsObject:kGTLAuthScopePlusLogin]) {
      label = [label stringByAppendingFormat:@" (Native Sharebox)"];
    }
  }

  cell.textLabel.adjustsFontSizeToFitWidth = YES;
  cell.textLabel.text = label;
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView
    shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *type = [_shareConfiguration typeForCellAtIndexPath:indexPath];

  // Only drilldown cells should be highlightable (other cells have
  // in-cell controls that would like strange when the cell is highlighted.
  return [type isEqualToString:kCellTypeDrilldown];
}

#pragma mark - ListPeopleViewControllerDelegate

- (void)viewController:(ListPeopleViewController *)viewController didPickPeople:(NSArray *)people {
  [self.navigationController popViewControllerAnimated:YES];
  _shareConfiguration.sharePrefillPeople = people;
}

#pragma mark - Event actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView endEditing:YES];
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if ([cell.textLabel.text isEqualToString:kCallToActionLabelDrilldownLabel]) {
    DataPickerState *pickerState = _shareConfiguration.callToActionLabelState;
    DataPickerViewController *dataPicker =
        [[DataPickerViewController alloc] initWithNibName:nil
                                                   bundle:nil
                                                dataState:pickerState];
    [self.navigationController pushViewController:dataPicker animated:YES];
  } else if ([cell.textLabel.text isEqualToString:kAttachAssetFromLibraryDrilldownLabel]) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[ (NSString *)kUTTypeImage, (NSString *)kUTTypeMovie ];
    picker.delegate = self;
    // Fork here to show a UIPopoverController for iPads, as it cannot handle modal views.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      UIPopoverController *popover =
        [[UIPopoverController alloc] initWithContentViewController:picker];
      [popover presentPopoverFromRect:CGRectMake(250, 20, 1, 1)
                               inView:cell
             permittedArrowDirections:UIPopoverArrowDirectionAny
                             animated:YES];
      _assetLibraryPopover = popover;
    } else {
      [self presentViewController:picker animated:YES completion:nil];
    }
  } else if ([cell.textLabel.text isEqualToString:kAttachAssetFromBundleDrilldownLabel]) {
    ShareBundleMediaPickerController *picker =
        [[ShareBundleMediaPickerController alloc] initWithNibName:nil bundle:nil];
    picker.delegate = self;
    [self.navigationController pushViewController:picker animated:YES];
  } else if ([cell.textLabel.text hasPrefix:kPrefillAudiencesDrilldownLabel]) {
    if (![GPPSignIn sharedInstance].authentication ||
        ![[GPPSignIn sharedInstance].scopes containsObject:kGTLAuthScopePlusLogin]) {
      // User is not signed in - do nothing.
      return;
    }
    ListPeopleViewController *peoplePicker =
        [[ListPeopleViewController alloc] initWithNibName:nil bundle:nil];
    peoplePicker.allowSelection = YES;
    peoplePicker.delegate = self;
    peoplePicker.navigationItem.title = @"Pick people";
    [self.navigationController pushViewController:peoplePicker animated:YES];
  } else {
    UIViewController *viewController = [[UIViewController alloc] init];
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont fontWithName:@"Helvetica" size:18];
    textView.text = [_shareConfiguration textForCellAtIndexPath:indexPath];
    // To identify it in the delegate method, we mark which section |textView| was activated from.
    textView.tag = indexPath.section;
    textView.delegate = self;
    textView.accessibilityIdentifier = @"share_view_text_view";

    viewController.view = textView;
    viewController.navigationItem.title = [_shareConfiguration labelForCellAtIndexPath:indexPath];
    [self.navigationController pushViewController:viewController animated:YES];
  }
}

- (void)toggleUseNativeSharebox:(UISwitch *)sender {
  [ShareConfiguration sharedInstance].useNativeSharebox = sender.on;
}

- (void)toggleURLEnabled:(UISwitch *)toggleSwitch {
  if (_shareConfiguration.urlEnabled == toggleSwitch.on) {
    return;
  }

  _shareConfiguration.urlEnabled = toggleSwitch.on;
  [self toggleRowsToState:_shareConfiguration.urlEnabled section:kURLSection];
}

- (void)toggleMediaEnabled:(UISwitch *)toggleSwitch {
  if (_shareConfiguration.mediaAttachmentEnabled == toggleSwitch.on) {
    return;
  }

  _shareConfiguration.mediaAttachmentEnabled = toggleSwitch.on;
  [self toggleRowsToState:_shareConfiguration.mediaAttachmentEnabled section:kMediaSection];
}

- (void)toggleCallToActionEnabled:(UISwitch *)toggleSwitch {
  if (_shareConfiguration.callToActionEnabled == toggleSwitch.on) {
    return;
  }

  _shareConfiguration.callToActionEnabled = toggleSwitch.on;
  [self toggleRowsToState:_shareConfiguration.callToActionEnabled
                  section:kCallToActionSection];
}

- (void)toggleDeepLinkEnabled:(UISwitch *)toggleSwitch {
  if (_shareConfiguration.deepLinkEnabled == toggleSwitch.on) {
    return;
  }

  _shareConfiguration.deepLinkEnabled = toggleSwitch.on;
  [self toggleRowsToState:_shareConfiguration.deepLinkEnabled section:kDeepLinkSection];
}

// For a given section, make visible or not visible all rows except
// the first (to be called when the properties callToActionEnabled
// and deepLinkEnabled are toggled.
- (void)toggleRowsToState:(BOOL)visible section:(NSUInteger)section {
  NSUInteger sectionSize = [_shareConfiguration numberOfCellsInSection:section];
  NSMutableArray *changingRows = [[NSMutableArray alloc] init];

  for (NSUInteger row = 1; row < sectionSize; row++) {
    [changingRows addObject:[NSIndexPath indexPathForItem:row inSection:section]];
  }

  if (visible) {
    [self.tableView insertRowsAtIndexPaths:changingRows
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  } else {
    [self.tableView deleteRowsAtIndexPaths:changingRows
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
  // |textView|'s tag identifies which section in the table view it belongs to.
  if (textView.tag == kShareOptionsSection) {
    _shareConfiguration.sharePrefillText = textView.text;
  } else if (textView.tag == kDeepLinkSection) {
    _shareConfiguration.contentDeepLinkDescription = textView.text;
  }
}

# pragma mark - Share

- (IBAction)shareButton:(id)sender {
  id<GPPShareBuilder> shareBuilder = [self shareBuilder];
  _shareStatus.text = @"Status: Sharing...";
  if (![shareBuilder open]) {
    _shareStatus.text = @"Status: Error (see console).";
  }
}

// Launches share sheet which includes a G+ share option.
- (void)shareSheetButton:(id)sender {
  ShareActivity *shareActivity = [[ShareActivity alloc] init];

  NSMutableArray *activityItems = [NSMutableArray array];
  [activityItems addObject:[self shareBuilder]];

  // Although we only need to pass the GPPShareBuilder to ShareActivity, we also add the user post
  // and the URL if any, which allow the share sheet to present other share options for these types
  // of data.
  if (_shareConfiguration.sharePrefillText.length) {
    [activityItems addObject:_shareConfiguration.sharePrefillText];
  }
  if (_shareConfiguration.urlEnabled) {
    [activityItems addObject:[NSURL URLWithString:_shareConfiguration.shareURL]];
  }

  NSArray *activities = @[ shareActivity ];
  UIActivityViewController *activityViewController =
      [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                        applicationActivities:activities];
  [self presentViewController:activityViewController animated:YES completion:nil];
}

- (id<GPPShareBuilder>)shareBuilder {
  // End editing to make sure all changes are saved to _shareConfiguration.
  [self.view endEditing:YES];

  // Create the share builder instance.
  id<GPPShareBuilder> shareBuilder = _shareConfiguration.useNativeSharebox ?
                                         [[GPPShare sharedInstance] nativeShareDialog] :
                                         [[GPPShare sharedInstance] shareDialog];

  if (_shareConfiguration.urlEnabled) {
    NSString *inputURL = _shareConfiguration.shareURL;
    NSURL *urlToShare = [inputURL length] ? [NSURL URLWithString:inputURL] : nil;
    if (urlToShare) {
      [shareBuilder setURLToShare:urlToShare];
    }
  }

  // Add deep link content.
  if (_shareConfiguration.deepLinkEnabled) {
    [shareBuilder setContentDeepLinkID:_shareConfiguration.contentDeepLinkID];
    NSString *title = _shareConfiguration.contentDeepLinkTitle;
    NSString *description = _shareConfiguration.contentDeepLinkDescription;
    NSString *urlString = _shareConfiguration.contentDeepLinkThumbnailURL;
    NSURL *thumbnailURL = urlString.length ? [NSURL URLWithString:urlString] : nil;
    [shareBuilder setTitle:title description:description thumbnailURL:thumbnailURL];
  }

  NSString *inputText = _shareConfiguration.sharePrefillText;
  NSString *text = [inputText length] ? inputText : nil;
  if (text) {
    [shareBuilder setPrefillText:text];
  }


  if (_shareConfiguration.callToActionEnabled) {
    // Please replace the URL below with your own call-to-action button URL.
    NSString *selectedCallToAction =
        [_shareConfiguration.callToActionLabelState.selectedCells anyObject];
    NSURL *callToActionURL = [NSURL URLWithString:_shareConfiguration.callToActionURL];

    NSString *deepLinkID = _shareConfiguration.callToActionDeepLinkID;
    [shareBuilder setCallToActionButtonWithLabel:selectedCallToAction
                                             URL:callToActionURL
                                      deepLinkID:deepLinkID];
  }

  // Attach media if we are using the native sharebox and have selected a media element.,
  if (_shareConfiguration.useNativeSharebox) {
    if (_shareConfiguration.mediaAttachmentEnabled) {
      if (_shareConfiguration.attachmentImage) {
        [(id<GPPNativeShareBuilder>)shareBuilder attachImage:_shareConfiguration.attachmentImage];
      } else if (_shareConfiguration.attachmentVideoURL) {
        [(id<GPPNativeShareBuilder>)shareBuilder attachVideoURL:
             _shareConfiguration.attachmentVideoURL];
      }
    }
    if (_shareConfiguration.sharePrefillPeople.count) {
      [(id<GPPNativeShareBuilder>)shareBuilder
          setPreselectedPeopleIDs:_shareConfiguration.sharePrefillPeople];
    }
  }

  return shareBuilder;
}

#pragma mark - Helper methods

- (UITableViewCell *)editableCellForTableView:(UITableView *)tableView
                                    indexPath:(NSIndexPath *)indexPath {
  EditableCell *editableCell =
      (EditableCell *)[tableView dequeueReusableCellWithIdentifier:kCellTypeEditable];
  if (!editableCell) {
    editableCell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:kCellTypeEditable];
  }
  // Populate text field with the current stored value for this field.
  editableCell.textField.text = [_shareConfiguration textForCellAtIndexPath:indexPath];

  // Associate this text field with its property in |_shareConfiguration|.
  editableCell.associatedProperty = [_shareConfiguration propertyForCellAtIndexPath:indexPath];
  editableCell.associatedPropertyOwner = _shareConfiguration;
  editableCell.textField.accessibilityIdentifier = [NSString stringWithFormat:@"%@ text_field",
                                                    editableCell.associatedProperty];
  return editableCell;
}

- (UITableViewCell *)switchCellForTableView:(UITableView *)tableView
                                  indexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeSwitch];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellTypeSwitch];

    UISwitch *toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = toggleSwitch;
  }
  // Reset switch accessory to have the correct value for |enabled|, |on|, and to target the
  // correct selector when its value changes.
  UISwitch *toggleSwitch = (UISwitch *)cell.accessoryView;
  toggleSwitch.enabled = YES;
  [toggleSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];

  NSString *label = [_shareConfiguration labelForCellAtIndexPath:indexPath];
  if ([label isEqualToString:kAddCallToActionLabel]) {
    toggleSwitch.on = _shareConfiguration.callToActionEnabled;
    [toggleSwitch addTarget:self
                     action:@selector(toggleCallToActionEnabled:)
           forControlEvents:UIControlEventValueChanged];

    if (![GPPSignIn sharedInstance].authentication ||
        ![[GPPSignIn sharedInstance].scopes containsObject:kGTLAuthScopePlusLogin]) {
      // If not logged in, then a call to action cannot be added.
      toggleSwitch.enabled = NO;
    }
  } else if ([label isEqualToString:kAddDeepLinkLabel]) {
    toggleSwitch.on = _shareConfiguration.deepLinkEnabled;
    [toggleSwitch addTarget:self
                     action:@selector(toggleDeepLinkEnabled:)
           forControlEvents:UIControlEventValueChanged];
  } else if ([label isEqualToString:kAddMediaLabel]) {
    toggleSwitch.on = _shareConfiguration.mediaAttachmentEnabled;
    [toggleSwitch addTarget:self
                     action:@selector(toggleMediaEnabled:)
           forControlEvents:UIControlEventValueChanged];
  } else if ([label isEqualToString:kAddURLLabel]) {
    toggleSwitch.on = _shareConfiguration.urlEnabled;
    [toggleSwitch addTarget:self
                     action:@selector(toggleURLEnabled:)
           forControlEvents:UIControlEventValueChanged];
  }

  toggleSwitch.accessibilityIdentifier = [NSString stringWithFormat:@"%@ switch", label];
  return cell;
}

- (UITableViewCell *)drilldownCellForTableView:(UITableView *)tableView
                                     indexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeDrilldown];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellTypeDrilldown];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  return cell;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *mediaType = info[UIImagePickerControllerMediaType];
  if ([mediaType isEqualToString:@"public.movie"]) {
    _shareConfiguration.attachmentImage = nil;
    _shareConfiguration.attachmentVideoURL = info[UIImagePickerControllerReferenceURL];
  } else {
    _shareConfiguration.attachmentImage = info[UIImagePickerControllerOriginalImage];
    _shareConfiguration.attachmentVideoURL = nil;
  }
  if (_assetLibraryPopover) {
    [_assetLibraryPopover dismissPopoverAnimated:YES];
    _assetLibraryPopover = nil;
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)selectedImage:(UIImage *)image {
  _shareConfiguration.attachmentImage = image;
  _shareConfiguration.attachmentVideoURL = nil;
}

- (void)selectedVideo:(NSURL *)videoURL {
  _shareConfiguration.attachmentImage = nil;
  _shareConfiguration.attachmentVideoURL = videoURL;
}

@end

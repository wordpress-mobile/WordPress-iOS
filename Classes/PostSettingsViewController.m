#import "PostSettingsViewController.h"
#import "WPSelectionTableViewController.h"
#import "WordPressAppDelegate.h"

#define kPasswordFooterSectionHeight         68.0f
#define kResizePhotoSettingSectionHeight     60.0f
#define TAG_PICKER_STATUS       0
#define TAG_PICKER_VISIBILITY   1
#define TAG_PICKER_DATE         2

@interface PostSettingsViewController (Private)

- (void)showPicker:(UIView *)picker;
- (void)geocodeCoordinate:(CLLocationCoordinate2D)c;

@end

@implementation PostSettingsViewController
@synthesize postDetailViewController;

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (locationManager) {
		locationManager.delegate = nil;
		[locationManager stopUpdatingLocation];
		[locationManager release];
	}
	if (reverseGeocoder) {
		reverseGeocoder.delegate = nil;
		[reverseGeocoder cancel];
		[reverseGeocoder release];
	}
	[address release];
	[addGeotagTableViewCell release];
    [mapGeotagTableViewCell release];
    [removeGeotagTableViewCell release];
	mapView.delegate = nil;
	[mapView release];
	[addressLabel release];
	[coordinateLabel release];
	
    [actionSheet release];
    [popover release];
    [pickerView release];
    [datePickerView release];
    [visibilityList release];
    [statusList release];

    [super dealloc];
}

- (void)endEditingAction:(id)sender {
	if (passwordTextField != nil){
    [passwordTextField resignFirstResponder];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	postDetailViewController.apost.password = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)endEditingForTextFieldAction:(id)sender {
    [passwordTextField endEditing:YES];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];

    statusTitleLabel.text = NSLocalizedString(@"Status", @"");
    visibilityTitleLabel.text = NSLocalizedString(@"Visibility", @"");
    passwordTextField.placeholder = NSLocalizedString(@"Enter a password", @"");
    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[postDetailViewController.apost availableStatuses]];
    [allStatuses removeObject:NSLocalizedString(@"Private", @"")];
    statusList = [[NSArray arrayWithArray:allStatuses] retain];
    visibilityList = [[NSArray arrayWithObjects:NSLocalizedString(@"Public", @""), NSLocalizedString(@"Password protected", @""), NSLocalizedString(@"Private", @""), nil] retain];

    CGRect pickerFrame;
	if (DeviceIsPad())
		pickerFrame = CGRectMake(0, 0, 320, 216);  
	else 
		pickerFrame = CGRectMake(0, 40, 320, 216);    
    pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    isShowingKeyboard = NO;
    datePickerView = [[UIDatePicker alloc] initWithFrame:pickerView.frame];
    datePickerView.minuteInterval = 5;
    [datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];

    if (!DeviceIsPad()) {
        /*UIToolbar *accesoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
        accesoryToolbar.tintColor = postDetailViewController.toolbar.tintColor;
        NSMutableArray *barButtons = [NSMutableArray arrayWithCapacity:2];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [barButtons addObject:barButton];
        [barButton release];
        barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditingAction:)];
        [barButtons addObject:barButton];
        [barButton release];
        accesoryToolbar.items = barButtons;
		
		//check iOS version for support of inputAccessoryView
		float version = [[[UIDevice currentDevice] systemVersion] floatValue];
		if (version >= 3.2)
			passwordTextField.inputAccessoryView = accesoryToolbar;
		else {
			passwordTextField.returnKeyType = UIReturnKeyDone;
			passwordTextField.delegate = self;
		}
        [accesoryToolbar release];*/
    }
	
	passwordTextField.returnKeyType = UIReturnKeyDone;
	passwordTextField.delegate = self;
	
	if (postDetailViewController.post) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
		locationManager.distanceFilter = 10;
		
		// FIXME: only add tag if it's a new post. If user removes tag we shouldn't try to add it again
		if (postDetailViewController.post.geolocation == nil // Only if there is no geotag
//			&& ![postDetailViewController.post hasRemote]    // and post is new (don't follow this way, instead tale look the line below)
			&& [postDetailViewController isAFreshlyCreatedDraft] //just a fresh draft. the line above doesn't take in consideration the case of a local draft without location
			&& [CLLocationManager locationServicesEnabled]
			&& postDetailViewController.post.blog.geolocationEnabled) {
			isUpdatingLocation = YES;
			[locationManager startUpdatingLocation];
		}
	}
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
    [locationManager release];
    locationManager = nil;
    
    [mapView release];
    mapView = nil;
    
    [reverseGeocoder cancel];
    reverseGeocoder.delegate = nil;
    [reverseGeocoder release];
    reverseGeocoder = nil;
    
    statusTitleLabel = nil;
    visibilityTitleLabel = nil;
    passwordTextField = nil;

    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self reloadData];
	[statusTableViewCell becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}
	
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
    if ([delegate isAlertRunning] == YES)
        return NO;
	
    // Return YES for supported orientations
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (postDetailViewController.post &&  postDetailViewController.post.blog.geolocationEnabled ) {
		return 2; // Geolocation
	} else {
		return 1; // Pages don't have geolocation
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 3;
	} else if (section == 1) {
		if (postDetailViewController.post.geolocation)
			return 3; // Add/Update | Map | Remove
		else
			return 1; // Add
	}

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"Publish", @"");
	else if (section == 1)
		return NSLocalizedString(@"Geolocation", @"");
	else
		return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
	case 0:
		switch (indexPath.row) {
			case 0:
				if (([postDetailViewController.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)
					&& ([postDetailViewController.apost.status isEqualToString:@"publish"])) {
					statusLabel.text = NSLocalizedString(@"Scheduled", @"");
				} else {
					statusLabel.text = postDetailViewController.apost.statusTitle;
				}
				if ([postDetailViewController.apost.status isEqualToString:@"private"])
					statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
				else
					statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;
				
				return statusTableViewCell;
				break;
			case 1:
				if (postDetailViewController.apost.password) {
					passwordTextField.text = postDetailViewController.apost.password;
					passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
					visibilityLabel.text = NSLocalizedString(@"Password protected", @"");
				} else if ([postDetailViewController.apost.status isEqualToString:@"private"]) {
					visibilityLabel.text = NSLocalizedString(@"Private", @"");
				} else {
					visibilityLabel.text = NSLocalizedString(@"Public", @"");
				}
				
				return visibilityTableViewCell;
				break;
			case 2:
			{
				if (postDetailViewController.apost.dateCreated) {
					if ([postDetailViewController.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending) {
						publishOnLabel.text = NSLocalizedString(@"Scheduled for", @"");
					} else {
						publishOnLabel.text = NSLocalizedString(@"Published on", @"Published on <date>");
					}
					
					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
					[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
					publishOnDateLabel.text = [dateFormatter stringFromDate:postDetailViewController.apost.dateCreated];
					[dateFormatter release];
				} else {
					publishOnLabel.text = NSLocalizedString(@"Publish   ", @""); //dorky spacing fix
					publishOnDateLabel.text = NSLocalizedString(@"Immediately", @"");
				}
				// Resize labels properly
				CGRect frame = publishOnLabel.frame;
				CGSize size = [publishOnLabel.text sizeWithFont:publishOnLabel.font];
				frame.size.width = size.width;
				publishOnLabel.frame = frame;
				frame = publishOnDateLabel.frame;
				frame.origin.x = publishOnLabel.frame.origin.x + publishOnLabel.frame.size.width + 8;
				frame.size.width = publishOnTableViewCell.frame.size.width - frame.origin.x - 8;
				publishOnDateLabel.frame = frame;
				
				return publishOnTableViewCell;
			}
			default:
				break;
		}
		break;
	case 1: // Geolocation
		switch (indexPath.row) {
			case 0: // Add/update location
				if (addGeotagTableViewCell == nil) {
					NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
					for(id currentObject in topLevelObjects) {
						if([currentObject isKindOfClass:[UITableViewActivityCell class]]) {
							addGeotagTableViewCell = (UITableViewActivityCell *)[currentObject retain];
							break;
						}
					}
				}
				if (isUpdatingLocation) {
					addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Finding your location...", @"");
					[addGeotagTableViewCell.spinner startAnimating];
				} else {
					[addGeotagTableViewCell.spinner stopAnimating];
					if (postDetailViewController.post.geolocation) {
						addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Update Location", @"");
					} else {
						addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Add Location", @"");
					}
				}
				return addGeotagTableViewCell;
				break;
			case 1:
				NSLog(@"Reloading map");
				if (mapGeotagTableViewCell == nil)
					mapGeotagTableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 188)];
				if (mapView == nil)
					mapView = [[MKMapView alloc] initWithFrame:CGRectMake(10, 0, 300, 130)];
				[mapView removeAnnotation:annotation];
				[annotation release];
				annotation = [[PostAnnotation alloc] initWithCoordinate:postDetailViewController.post.geolocation.coordinate];
				[mapView addAnnotation:annotation];

				if (addressLabel == nil)
					addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 130, 280, 30)];
				if (coordinateLabel == nil)
					coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 162, 280, 20)];

				// Set center of map and show a region of around 200x100 meters
				MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(postDetailViewController.post.geolocation.coordinate, 200, 100);
				[mapView setRegion:region animated:YES];
				if (address) {
					addressLabel.text = address;
				} else {
					addressLabel.text = NSLocalizedString(@"Finding address...", @"");
					[self geocodeCoordinate:postDetailViewController.post.geolocation.coordinate];
				}
				addressLabel.font = [UIFont boldSystemFontOfSize:16];
				addressLabel.textColor = [UIColor darkGrayColor];
				CLLocationDegrees latitude = postDetailViewController.post.geolocation.latitude;
				CLLocationDegrees longitude = postDetailViewController.post.geolocation.longitude;
				int latD = trunc(fabs(latitude));
				int latM = trunc((fabs(latitude) - latD) * 60);
				int lonD = trunc(fabs(longitude));
				int lonM = trunc((fabs(longitude) - lonD) * 60);
				NSString *latDir = (latitude > 0) ? NSLocalizedString(@"North", @"") : NSLocalizedString(@"South", @"");
				NSString *lonDir = (longitude > 0) ? NSLocalizedString(@"East", @"") : NSLocalizedString(@"West", @"");
				if (latitude == 0.0) latDir = @"";
				if (longitude == 0.0) lonDir = @"";

				coordinateLabel.text = [NSString stringWithFormat:@"%i°%i' %@, %i°%i' %@",
										latD, latM, latDir,
										lonD, lonM, lonDir];
//				coordinateLabel.text = [NSString stringWithFormat:@"%.6f, %.6f",
//										postDetailViewController.post.geolocation.latitude,
//										postDetailViewController.post.geolocation.longitude];
				coordinateLabel.font = [UIFont italicSystemFontOfSize:13];
				coordinateLabel.textColor = [UIColor darkGrayColor];
				
				[mapGeotagTableViewCell addSubview:mapView];
				[mapGeotagTableViewCell addSubview:addressLabel];
				[mapGeotagTableViewCell addSubview:coordinateLabel];

				return mapGeotagTableViewCell;
				break;
			case 2:
				if (removeGeotagTableViewCell == nil)
					removeGeotagTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RemoveGeotag"];
				removeGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Remove Location", @"");
				removeGeotagTableViewCell.textLabel.textAlignment = UITextAlignmentCenter;
				return removeGeotagTableViewCell;
				break;

		}
	}
	
    // Configure the cell
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 1) && (postDetailViewController.apost.password))
        return 88.f;
    else if ((indexPath.section == 1) && (indexPath.row == 1))
		return 188.0f;
	else
        return 44.0f;
}

- (void)reloadData {
    passwordTextField.text = postDetailViewController.apost.password;
	
    [tableView reloadData];
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					if ([postDetailViewController.apost.status isEqualToString:@"private"])
						break;

					pickerView.tag = TAG_PICKER_STATUS;
					[pickerView reloadAllComponents];
					[pickerView selectRow:[statusList indexOfObject:postDetailViewController.apost.statusTitle] inComponent:0 animated:NO];
					[self showPicker:pickerView];
					break;
				}
				case 1:
				{
					pickerView.tag = TAG_PICKER_VISIBILITY;
					[pickerView reloadAllComponents];
					[pickerView selectRow:[visibilityList indexOfObject:visibilityLabel.text] inComponent:0 animated:NO];
					[self showPicker:pickerView];
					break;
				}
				case 2:
					datePickerView.tag = TAG_PICKER_DATE;
					if (postDetailViewController.apost.dateCreated)
						datePickerView.date = postDetailViewController.apost.dateCreated;
					else
						datePickerView.date = [NSDate date];            
					[self showPicker:datePickerView];
					break;

				default:
					break;
			}
			break;
		case 1:
			switch (indexPath.row) {
				case 0:
					if (!isUpdatingLocation) {
						// Add or replace geotag
						isUpdatingLocation = YES;
						[locationManager startUpdatingLocation];
					}
					break;
				case 2:
					if (isUpdatingLocation) {
						// Cancel update
						isUpdatingLocation = NO;
						[locationManager stopUpdatingLocation];
					}
					postDetailViewController.post.geolocation = nil;
					postDetailViewController.hasLocation.enabled = NO;
					
					break;
					
			}
			[tableView reloadData];
	}
    [atableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [statusList count];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [visibilityList count];
    }
    return 0;
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [visibilityList objectAtIndex:row];
    }

    return @"";
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        postDetailViewController.apost.statusTitle = [statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        NSString *visibility = [visibilityList objectAtIndex:row];
        if ([visibility isEqualToString:NSLocalizedString(@"Private", @"")]) {
            postDetailViewController.apost.status = @"private";
            postDetailViewController.apost.password = nil;
        } else {
            if ([postDetailViewController.apost.status isEqualToString:@"private"]) {
                postDetailViewController.apost.status = @"publish";
            }
            if ([visibility isEqualToString:NSLocalizedString(@"Password protected", @"")]) {
                postDetailViewController.apost.password = @"";
            } else {
                postDetailViewController.apost.password = nil;
            }
        }
    }
	[postDetailViewController refreshButtons];
    [tableView reloadData];
}

- (void)datePickerChanged {
    postDetailViewController.apost.dateCreated = datePickerView.date;
	[postDetailViewController refreshButtons];
    [tableView reloadData];
}

#pragma mark -
#pragma mark Pickers and keyboard animations

- (void)showPicker:(UIView *)picker {
    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];
    
    if (DeviceIsPad()) {
        if (popover)
            [popover release];
        UIViewController *fakeController = [[UIViewController alloc] init];
        if (picker.tag == TAG_PICKER_DATE) {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320, 256);

            UISegmentedControl *publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Publish Immediately", @"")]];
            publishNowButton.momentary = YES; 
            publishNowButton.frame = CGRectMake(0, 0, 320, 40);
            publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
            publishNowButton.tintColor = postDetailViewController.toolbar.tintColor;
            [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
            [fakeController.view addSubview:publishNowButton];
            [publishNowButton release];
            CGRect frame = picker.frame;
            frame.origin.y = 40;
            picker.frame = frame;
        } else {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320, 216);
        }

        
        [fakeController.view addSubview:picker];
        popover = [[UIPopoverController alloc] initWithContentViewController:fakeController];
        [fakeController release];
        
        CGRect popoverRect;
        if (picker.tag == TAG_PICKER_STATUS)
            popoverRect = [self.view convertRect:statusLabel.frame fromView:[statusLabel superview]];
        else if (picker.tag == TAG_PICKER_VISIBILITY)
            popoverRect = [self.view convertRect:visibilityLabel.frame fromView:[visibilityLabel superview]];
        else 
            popoverRect = [self.view convertRect:publishOnDateLabel.frame fromView:[publishOnDateLabel superview]];

        popoverRect.size.width = 100;
        [popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleAutomatic];
        [actionSheet addSubview:picker];
		UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Done", @"")]];
		closeButton.momentary = YES; 
		closeButton.frame = CGRectMake(260, 7, 50, 30);
		closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
		closeButton.tintColor = [UIColor blackColor];
		[closeButton addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventValueChanged];
		[actionSheet addSubview:closeButton];
		[closeButton release];

        if (picker.tag == TAG_PICKER_DATE) {
            UISegmentedControl *publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Publish Immediately", @"")]];
            publishNowButton.momentary = YES; 
            publishNowButton.frame = CGRectMake(10, 7, 129, 30);
            publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
            publishNowButton.tintColor = [UIColor blackColor];
            [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
            [actionSheet addSubview:publishNowButton];
            [publishNowButton release];            
        }
		[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		[actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (void)hidePicker {
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [actionSheet release]; actionSheet = nil;
}

- (void)removeDate {
    datePickerView.date = [NSDate date];
    postDetailViewController.apost.dateCreated = nil;
    [tableView reloadData];
    if (DeviceIsPad())
        [popover dismissPopoverAnimated:YES];
    else
        [self hidePicker];

}

- (void)keyboardWillShow:(NSNotification *)keyboardInfo {
    isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)keyboardInfo {
    isShowingKeyboard = NO;
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
		if (!isUpdatingLocation) {
			return;
		}
		isUpdatingLocation = NO;
		CLLocationCoordinate2D coordinate = newLocation.coordinate;
#if FALSE // Switch this on/off for testing location updates
		// Factor values (YMMV)
		// 0.0001 ~> whithin your zip code (for testing small map changes)
		// 0.01 ~> nearby cities (good for testing address label changes)
		double factor = 0.001f; 
		coordinate.latitude += factor * (rand() % 100);
		coordinate.longitude += factor * (rand() % 100);
#endif
		Coordinate *c = [[Coordinate alloc] initWithCoordinate:coordinate];
		postDetailViewController.post.geolocation = c;
		postDetailViewController.hasLocation.enabled = YES;
        WPLog(@"Added geotag (%+.6f, %+.6f)",
			  c.latitude,
			  c.longitude);
		[locationManager stopUpdatingLocation];
		[tableView reloadData];
		
		[self geocodeCoordinate:c.coordinate];

		[c release];
    }
    // else skip the event and process the next one.
}

#pragma mark -
#pragma mark MKReverseGeocoderDelegate

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
	if (address)
		[address release];
	if (placemark.subLocality) {
		address = [NSString stringWithFormat:@"%@, %@, %@", placemark.subLocality, placemark.locality, placemark.country];
	} else {
		address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
	}
	addressLabel.text = [address retain];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
	NSLog(@"Reverse geocoder failed for coordinate (%.6f, %.6f): %@",
		  geocoder.coordinate.latitude,
		  geocoder.coordinate.longitude,
		  [error localizedDescription]);
	if (address)
		[address release];
	
	address = [NSString stringWithString:NSLocalizedString(@"Location unknown", @"")];
	addressLabel.text = [address retain];
}

- (void)geocodeCoordinate:(CLLocationCoordinate2D)c {
	if (reverseGeocoder) {
		if (reverseGeocoder.querying)
			[reverseGeocoder cancel];
		[reverseGeocoder release];
	}
	reverseGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:c];
	reverseGeocoder.delegate = self;
	[reverseGeocoder start];	
}

@end

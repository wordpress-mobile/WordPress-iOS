#import "PostSettingsViewController.h"
#import "WPSelectionTableViewController.h"
#import "WordPressAppDelegate.h"
#import "WPPopoverBackgroundView.h"
#import "NSString+Helpers.h"
#import "EditPostViewController_Internal.h"
#import "PostSettingsSelectionViewController.h"
#import "NSString+XMLExtensions.h"
#import <ImageIO/ImageIO.h>
#import "WPSegmentedSelectionTableViewController.h"
#import "WPAddCategoryViewController.h"
#import "Post.h"

#define kPasswordFooterSectionHeight         68.0f
#define kResizePhotoSettingSectionHeight     60.0f
#define TAG_PICKER_STATUS       0
#define TAG_PICKER_VISIBILITY   1
#define TAG_PICKER_DATE         2
#define TAG_PICKER_FORMAT       3
#define TAG_ACTIONSHEET_PHOTO 10
#define TAG_ACTIONSHEET_RESIZE_PHOTO 20

@interface PostSettingsViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIPopoverControllerDelegate>  {
    BOOL triedAuthOnce;
    BOOL _isNewCategory;
    NSDictionary *_currentImageMetadata;
    BOOL _isShowingResizeActionSheet;
    BOOL _isShowingCustomSizeAlert;
    UIImage *_currentImage;
    UIAlertView *_customSizeAlert;
    WPSegmentedSelectionTableViewController *_segmentedTableViewController;
}

@property (nonatomic, strong) AbstractPost *apost;
- (void)showPicker:(UIView *)picker;
- (void)geocodeCoordinate:(CLLocationCoordinate2D)c;
- (void)geolocationCellTapped:(NSIndexPath *)indexPath;
- (void)loadFeaturedImage:(NSURL *)imageURL;

@end

@implementation PostSettingsViewController
@synthesize postDetailViewController, postFormatTableViewCell;

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (locationManager) {
		locationManager.delegate = nil;
		[locationManager stopUpdatingLocation];
	}
	if (reverseGeocoder) {
		[reverseGeocoder cancelGeocode];
	}
	mapView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super init];
    if (self) {
        self.apost = aPost;
    }
    return self;
}

- (NSString *)statsPrefix {
    if (_statsPrefix == nil) {
        return @"Post Detail";
    } else {
        return _statsPrefix;
    }
}

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Properties", nil);
    
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFeaturedImageUploader:) name:@"UploadingFeaturedImage" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadSucceeded:) name:FeaturedImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadFailed:) name:FeaturedImageUploadFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
    
    [tableView setBackgroundView:nil];
    [tableView setBackgroundColor:[UIColor clearColor]]; //Fix for black corners on iOS4. http://stackoverflow.com/questions/1557856/black-corners-on-uitableview-group-style
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    tableView.separatorColor = [WPStyleGuide readGrey];
    
    
    statusTitleLabel.text = NSLocalizedString(@"Status", @"The status of the post. Should be the same as in core WP.");
    visibilityTitleLabel.text = NSLocalizedString(@"Visibility", @"The visibility settings of the post. Should be the same as in core WP.");
    postFormatTitleLabel.text = NSLocalizedString(@"Post Format", @"The post formats available for the post. Should be the same as in core WP.");
    passwordTextField.placeholder = NSLocalizedString(@"Enter a password", @"");
    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[self.apost availableStatuses]];
    [allStatuses removeObject:NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    statusList = [NSArray arrayWithArray:allStatuses];
    visibilityList = [NSArray arrayWithObjects:NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."), NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."), NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP."), nil];
    formatsList = self.post.blog.sortedPostFormatNames;

    isShowingKeyboard = NO;
    
    CGRect pickerFrame;
	if (IS_IPAD)
		pickerFrame = CGRectMake(0.0f, 0.0f, 320.0f, 216.0f);
	else 
		pickerFrame = CGRectMake(0.0f, 44.0f, 320.0f, 216.0f);
    
    pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
        
    datePickerView = [[UIDatePicker alloc] initWithFrame:pickerView.frame];
    datePickerView.minuteInterval = 5;
    [datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];

    passwordTextField.returnKeyType = UIReturnKeyDone;
	passwordTextField.delegate = self;
	
	if (self.post) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
		locationManager.distanceFilter = 10;
		
		// Only add tag if it's a new post. If user removes tag we shouldn't try to add it again
		if (self.post.geolocation == nil // Only if there is no geotag
			&& self.apost.remoteStatus == AbstractPostRemoteStatusLocal // and just a fresh draft.
			&& [CLLocationManager locationServicesEnabled]
			&& self.post.blog.geolocationEnabled) {
			isUpdatingLocation = YES;
			[locationManager startUpdatingLocation];
		}
	}
    
    featuredImageView.layer.shadowOffset = CGSizeMake(0.0, 1.0f);
    featuredImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
    featuredImageView.layer.shadowOpacity = 0.5f;
    featuredImageView.layer.shadowRadius = 1.0f;
    
    // Check if blog supports featured images
    id supportsFeaturedImages = [self.post.blog getOptionValue:@"post_thumbnail"];
    if (supportsFeaturedImages != nil) {
        blogSupportsFeaturedImage = [supportsFeaturedImages boolValue];
        if (blogSupportsFeaturedImage && self.post.post_thumbnail != nil) {
            // Download the current featured image
            [featuredImageView setHidden:YES];
            [featuredImageLabel setText:NSLocalizedString(@"Loading Featured Image", @"Loading featured image in post settings")];
            [featuredImageLabel setHidden:NO];
            [featuredImageSpinner setHidden:NO];
            if (!featuredImageSpinner.isAnimating)
                [featuredImageSpinner startAnimating];
            [tableView reloadData];
            
            [self.post getFeaturedImageURLWithSuccess:^{
                if (self.post.featuredImageURL) {
                    NSURL *imageURL = [[NSURL alloc] initWithString:self.post.featuredImageURL];
                    if (imageURL) {
                        [featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
                        [self loadFeaturedImage:imageURL];
                    }
                }
            } failure:^(NSError *error) {
                [featuredImageView setHidden:YES];
                [featuredImageSpinner stopAnimating];
                [featuredImageSpinner setHidden:YES];
                [featuredImageLabel setText:NSLocalizedString(@"Could not download Featured Image.", @"Featured image could not be downloaded for display in post settings.")];
            }];
        }
    }
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTagsKeyboardIfAppropriate:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;
    [tableView addGestureRecognizer:gestureRecognizer];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
    locationManager = nil;
    
    mapView = nil;
    
    [reverseGeocoder cancelGeocode];
    reverseGeocoder = nil;
    
    statusTitleLabel = nil;
    visibilityTitleLabel = nil;
    postFormatTitleLabel = nil;
    passwordTextField = nil;
    featuredImageView = nil;
    featuredImageTableViewCell = nil;
    featuredImageLabel = nil;
    featuredImageLabel = nil;
    postFormatTableViewCell = nil;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
	[statusTableViewCell becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}


#pragma mark -
#pragma mark Instance Methods

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (void)loadFeaturedImage:(NSURL *)imageURL {
    
    NSURLRequest *req = [NSURLRequest requestWithURL:imageURL];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:req];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [featuredImageView setImage:responseObject];
        [featuredImageView setHidden:NO];
        [featuredImageSpinner stopAnimating];
        [featuredImageSpinner setHidden:YES];
        [featuredImageLabel setHidden:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // private blog, auth needed.
        if (operation.response.statusCode == 403) {
            
            if (!triedAuthOnce) {
                triedAuthOnce = YES;
                
                Blog *blog = self.apost.blog;
                NSString *username = blog.username;
                NSString *password = blog.password;
                
                NSMutableURLRequest *mRequest = [[NSMutableURLRequest alloc] init];
                NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=",
                                         [username stringByUrlEncoding],
                                         [password stringByUrlEncoding]];
                
                [mRequest setURL:[NSURL URLWithString:blog.loginUrl]];
                [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
                [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
                [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
                [mRequest setHTTPMethod:@"POST"];
                
                AFHTTPRequestOperation *authOp = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];
                [authOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    // Good auth. We should be able to show the image now.
                    [self loadFeaturedImage:imageURL];
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    // Rather than duplicate the fail condition, just call the method again and let it fail a second time.
                    [self loadFeaturedImage:imageURL];
                    
                }];
                [authOp start];
                
                return;
            }    
        }
        
        // Unable to download the image.
        [featuredImageView setHidden:YES];
        [featuredImageSpinner stopAnimating];
        [featuredImageSpinner setHidden:YES];
        [featuredImageLabel setText:NSLocalizedString(@"Could not download Featured Image.", @"Featured image could not be downloaded for display in post settings.")];
    }];
    
    [operation start];
}


- (void)endEditingAction:(id)sender {
	if (passwordTextField != nil){
        [passwordTextField resignFirstResponder];
	}
}

- (void)endEditingForTextFieldAction:(id)sender {
    [passwordTextField endEditing:YES];
}

- (void)reloadData {
    passwordTextField.text = self.apost.password;
	
    [tableView reloadData];
}

- (void)datePickerChanged {
    self.apost.dateCreated = datePickerView.date;
	[postDetailViewController refreshButtons];
    [tableView reloadData];
}

#pragma mark -
#pragma mark TextField Delegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.apost.password = textField.text;
    [postDetailViewController refreshButtons];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == tagsTextField) {
        self.post.tags = [tagsTextField.text stringByReplacingCharactersInRange:range withString:string];
    }
    
    return YES;
}



#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 1; // Always have the status section
	if (self.post) {
        sections += 1; // Post formats
        sections += 1; // Post Metadata
        if (blogSupportsFeaturedImage)
            sections += 1;
        if (self.post.blog.geolocationEnabled || self.post.geolocation) {
            sections += 1; // Geolocation
        }
	}
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.post)
            return 2; // Post Metadata
        else
            return 3;
    } else if (section == 1) {
		return 3;
    } else if (section == 2) {
        return 1;
    } else if (section == 3 && blogSupportsFeaturedImage) {
        if (self.post.post_thumbnail && !isUploadingFeaturedImage)
            return 2;
        else
            return 1;
	} else if ((section == 3 && !blogSupportsFeaturedImage) || section == 4) {
		if (self.post.geolocation)
			return 3; // Add/Update | Map | Remove
		else
			return 1; // Add
	}

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSUInteger alteredSection = section;
    if (!self.post && section == 0) {
        // We only show the status section for Pages
        alteredSection = 1;
    }

	if (alteredSection == 0) {
        return @"";
    } else if (alteredSection == 1) {
		return NSLocalizedString(@"Publish", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
    } else if (alteredSection == 2) {
		return NSLocalizedString(@"Post Format", @"For setting the format of a post.");
    } else if ((alteredSection == 3 && blogSupportsFeaturedImage)) {
		return NSLocalizedString(@"Featured Image", @"Label for the Featured Image area in post settings.");
    } else if ((alteredSection == 3 && !blogSupportsFeaturedImage) || alteredSection == 4) {
		return NSLocalizedString(@"Geolocation", @"Label for the geolocation feature (tagging posts by their physical location).");
    } else {
		return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (!self.post && section == 0) {
        // We only show the status section for Pages
        section = 1;
    }
    
	switch (section) {
    case 0:
            switch (indexPath.row) {
                case 0:
                    categoriesTitleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
                    categoriesTitleLabel.textColor = [WPStyleGuide whisperGrey];
                    categoriesTitleLabel.text = NSLocalizedString(@"Categories:", @"Label for the categories field. Should be the same as WP core.");
                    categoriesLabel.font = [WPStyleGuide tableviewTextFont];
                    categoriesLabel.textColor = [WPStyleGuide whisperGrey];
                    categoriesLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
                    return categoriesTableViewCell;
                    break;
                case 1:
                    tagsTitleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
                    tagsTitleLabel.textColor = [WPStyleGuide whisperGrey];
                    tagsTitleLabel.text = NSLocalizedString(@"Tags:", @"Label for the tags field. Should be the same as WP core.");
                    tagsTextField.placeholder = NSLocalizedString(@"Separate tags with commas", @"Placeholder text for the tags field. Should be the same as WP core.");
                    tagsTextField.font = [WPStyleGuide tableviewTextFont];
                    tagsTextField.textColor = [WPStyleGuide whisperGrey];
                    tagsTextField.text = self.post.tags;
                    return tagsTableViewCell;
                    break;
            }
	case 1:
		switch (indexPath.row) {
			case 0:
                statusTitleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
                statusTitleLabel.textColor = [WPStyleGuide whisperGrey];
                statusLabel.font = [WPStyleGuide tableviewTextFont];
                statusLabel.textColor = [WPStyleGuide whisperGrey];
				if (([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)
					&& ([self.apost.status isEqualToString:@"publish"])) {
					statusLabel.text = NSLocalizedString(@"Scheduled", @"If a post is scheduled for later, this string is used for the post's status. Should use the same translation as core WP.");
				} else {
					statusLabel.text = self.apost.statusTitle;
				}
				if ([self.apost.status isEqualToString:@"private"])
					statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
				else
					statusTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;
				
				return statusTableViewCell;
				break;
			case 1:
                visibilityTitleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
                visibilityTitleLabel.textColor = [WPStyleGuide whisperGrey];
                visibilityLabel.font = [WPStyleGuide tableviewTextFont];
                visibilityLabel.textColor = [WPStyleGuide whisperGrey];
				if (self.apost.password) {
					passwordTextField.text = self.apost.password;
					passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
				}
            
                visibilityLabel.text = [self titleForVisibility];
				
				return visibilityTableViewCell;
				break;
			case 2:
			{
                publishOnLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
                publishOnLabel.textColor = [WPStyleGuide whisperGrey];
                publishOnDateLabel.font = [WPStyleGuide tableviewTextFont];
                publishOnDateLabel.textColor = [WPStyleGuide whisperGrey];

				if (self.apost.dateCreated) {
					if ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending) {
						publishOnLabel.text = NSLocalizedString(@"Scheduled for", @"Scheduled for [date]");
					} else {
						publishOnLabel.text = NSLocalizedString(@"Published on", @"Published on [date]");
					}
					
					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
					[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
					publishOnDateLabel.text = [dateFormatter stringFromDate:self.apost.dateCreated];
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
    case 2: // Post format
        {
            postFormatTitleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
            postFormatTitleLabel.textColor = [WPStyleGuide whisperGrey];
            postFormatLabel.font = [WPStyleGuide tableviewTextFont];
            postFormatLabel.textColor = [WPStyleGuide whisperGrey];

            if ([formatsList count] != 0) {
                postFormatLabel.text = self.post.postFormatText;
            }
            return postFormatTableViewCell;
        }
	case 3:
        if (blogSupportsFeaturedImage) {
            if (!self.post.post_thumbnail && !isUploadingFeaturedImage) {
                UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
                if (activityCell == nil) {
                    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                    for(id currentObject in topLevelObjects)
                    {
                        if([currentObject isKindOfClass:[UITableViewActivityCell class]])
                        {
                            activityCell = (UITableViewActivityCell *)currentObject;
                            break;
                        }
                    }
                }
                activityCell.textLabel.font = [WPStyleGuide tableviewTextFont];
                activityCell.textLabel.textColor = [WPStyleGuide tableViewActionColor];
                [activityCell.textLabel setText:@"Set Featured Image"];
                return activityCell;
                
                
            } else {
                switch (indexPath.row) {
                    case 0:
                        if (featuredImageTableViewCell == nil) {
                            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                            for(id currentObject in topLevelObjects) {
                                if([currentObject isKindOfClass:[UITableViewActivityCell class]]) {
                                    featuredImageTableViewCell = (UITableViewActivityCell *)currentObject;
                                    break;
                                }
                            }
                        }
                        return featuredImageTableViewCell;
                        break;
                    case 1: {
                        UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
                        if (activityCell == nil) {
                            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                            for(id currentObject in topLevelObjects)
                            {
                                if([currentObject isKindOfClass:[UITableViewActivityCell class]])
                                {
                                    activityCell = (UITableViewActivityCell *)currentObject;
                                    break;
                                }
                            }
                        }
                        [activityCell.textLabel setText: NSLocalizedString(@"Remove Featured Image", "Remove featured image from post")];
                        return activityCell;
                        break;
                    }
                        
                }
            }
        } else {
            return [self getGeolactionCellWithIndexPath: indexPath];
        }
        break;
    case 4:
        return [self getGeolactionCellWithIndexPath: indexPath];
        break;
	}
    
    return nil;
}

- (UITableViewCell*) getGeolactionCellWithIndexPath: (NSIndexPath*)indexPath {
    switch (indexPath.row) {
        case 0: // Add/update location
        {
            // If location services are disabled at the app level [CLLocationManager locationServicesEnabled] will be true, but the location will be nil.
            if(!self.post.blog.geolocationEnabled) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeolocationDisabledCell"];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GeolocationDisabledCell"];
                    cell.textLabel.text = NSLocalizedString(@"Enable Geotagging to Edit", @"Prompt the user to enable geolocation tagging on their blog.");
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.font = [WPStyleGuide tableviewTextFont];
                    cell.textLabel.textColor = [WPStyleGuide tableViewActionColor];
                }
                return cell;
                
            } else if(![CLLocationManager locationServicesEnabled] || [locationManager location] == nil) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationServicesCell"];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"locationServicesCell"];
                    cell.textLabel.text = NSLocalizedString(@"Please Enable Location Services", @"Prompt the user to enable location services on their device.");
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                }
                return cell;
                
            } else {
            
                if (addGeotagTableViewCell == nil) {
                    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                    for(id currentObject in topLevelObjects) {
                        if([currentObject isKindOfClass:[UITableViewActivityCell class]]) {
                            addGeotagTableViewCell = (UITableViewActivityCell *)currentObject;
                            break;
                        }
                    }
                }
                if (isUpdatingLocation) {
                    addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");
                    [addGeotagTableViewCell.spinner startAnimating];
                } else {
                    [addGeotagTableViewCell.spinner stopAnimating];
                    if (self.post.geolocation) {
                        addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Update Location", @"Gelocation feature to update physical location.");
                    } else {
                        addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Add Location", @"Geolocation feature to add location.");
                    }
                }
                return addGeotagTableViewCell;
            }
            break;
        }
        case 1:
        {
            NSLog(@"Reloading map");
            if (mapGeotagTableViewCell == nil)
                mapGeotagTableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 188)];
            if (mapView == nil)
                mapView = [[MKMapView alloc] initWithFrame:CGRectMake(10, 0, 300, 130)];
            [mapView removeAnnotation:annotation];
            annotation = [[PostAnnotation alloc] initWithCoordinate:self.post.geolocation.coordinate];
            [mapView addAnnotation:annotation];
            
            if (addressLabel == nil)
                addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 130, 280, 30)];
            if (coordinateLabel == nil)
                coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 162, 280, 20)];
            
            // Set center of map and show a region of around 200x100 meters
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.post.geolocation.coordinate, 200, 100);
            [mapView setRegion:region animated:YES];
            if (address) {
                addressLabel.text = address;
            } else {
                addressLabel.text = NSLocalizedString(@"Finding address...", @"Used for Geo-tagging posts.");
                [self geocodeCoordinate:self.post.geolocation.coordinate];
            }
            addressLabel.font = [UIFont boldSystemFontOfSize:16];
            addressLabel.textColor = [UIColor darkGrayColor];
            CLLocationDegrees latitude = self.post.geolocation.latitude;
            CLLocationDegrees longitude = self.post.geolocation.longitude;
            int latD = trunc(fabs(latitude));
            int latM = trunc((fabs(latitude) - latD) * 60);
            int lonD = trunc(fabs(longitude));
            int lonM = trunc((fabs(longitude) - lonD) * 60);
            NSString *latDir = (latitude > 0) ? NSLocalizedString(@"North", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"South", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
            NSString *lonDir = (longitude > 0) ? NSLocalizedString(@"East", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"West", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
            if (latitude == 0.0) latDir = @"";
            if (longitude == 0.0) lonDir = @"";
            
            coordinateLabel.text = [NSString stringWithFormat:@"%i°%i' %@, %i°%i' %@",
                                    latD, latM, latDir,
                                    lonD, lonM, lonDir];
            //				coordinateLabel.text = [NSString stringWithFormat:@"%.6f, %.6f",
            //										self.post.geolocation.latitude,
            //										self.post.geolocation.longitude];
            coordinateLabel.font = [UIFont italicSystemFontOfSize:13];
            coordinateLabel.textColor = [UIColor darkGrayColor];
            
            [mapGeotagTableViewCell addSubview:mapView];
            [mapGeotagTableViewCell addSubview:addressLabel];
            [mapGeotagTableViewCell addSubview:coordinateLabel];
            
            return mapGeotagTableViewCell;
            break;
        }
        case 2:
        {
            if (removeGeotagTableViewCell == nil)
                removeGeotagTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RemoveGeotag"];
            removeGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Remove Location", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
            removeGeotagTableViewCell.textLabel.textAlignment = NSTextAlignmentCenter;
            return removeGeotagTableViewCell;
            break;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 1) && (indexPath.row == 1) && (self.apost.password))
        return 88.f;
    else if (
             (!blogSupportsFeaturedImage && (indexPath.section == 3) && (indexPath.row == 1))
             || (blogSupportsFeaturedImage && (self.post.post_thumbnail || isUploadingFeaturedImage) && indexPath.section == 3 && indexPath.row == 0)
             || (blogSupportsFeaturedImage && (indexPath.section == 4) && (indexPath.row == 1))
             )
		return 188.0f;
	else
        return 44.0f;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (!self.post && section == 0) {
        // We only show the status section for Pages
        section = 1;
    }

	switch (section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self showCategoriesSelectionView:[tableView cellForRowAtIndexPath:indexPath].frame];
                case 1:
                    break;
            }
            break;
		case 1:
			switch (indexPath.row) {
				case 0:
				{
					if ([self.apost.status isEqualToString:@"private"])
						break;
                    
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedStatus forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];

                    NSMutableArray *titles = [NSMutableArray arrayWithArray:[self.apost availableStatuses]];
                    [titles removeObject:NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
                    
                    NSDictionary *statusDict = @{
                                                    @"DefaultValue": NSLocalizedString(@"Published", @""),
                                                    @"Title" : NSLocalizedString(@"Status", nil),
                                                    @"Titles" : titles,
                                                    @"Values" : titles,
                                                    @"CurrentValue" : self.apost.statusTitle
                                                    };
                    PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:statusDict];
                    __weak PostSettingsSelectionViewController *weakVc = vc;
                    vc.onItemSelected = ^(NSString *status) {
                        [weakVc dismiss];
                        self.apost.status = status;
                        [tableView reloadData];
                    };
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
				}
				case 1:
				{
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedVisibility forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                    
                    NSArray *titles = @[
                                        NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                                        NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."),
                                        NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")
                                        ];
                    NSDictionary *visiblityDict = @{
                                                    @"DefaultValue": NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                                                    @"Title" : NSLocalizedString(@"Visiblity", nil),
                                                    @"Titles" : titles,
                                                    @"Values" : titles,
                                                    @"CurrentValue" : [self titleForVisibility]};
                    PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:visiblityDict];
                    __weak PostSettingsSelectionViewController *weakVc = vc;
                    vc.onItemSelected = ^(NSString *visibility) {
                        [weakVc dismiss];
                        
                        if ([visibility isEqualToString:NSLocalizedString(@"Private", @"Post privacy status in the Post Editor/Settings area (compare with WP core translations).")]) {
                            self.apost.status = @"private";
                            self.apost.password = nil;
                        } else {
                            if ([self.apost.status isEqualToString:@"private"]) {
                                self.apost.status = @"publish";
                            }
                            if ([visibility isEqualToString:NSLocalizedString(@"Password protected", @"Post password protection in the Post Editor/Settings area (compare with WP core translations).")]) {
                                self.apost.password = @"";
                            } else {
                                self.apost.password = nil;
                            }
                        }
                        
                        [tableView reloadData];
                    };
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
				}
				case 2:
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedScheduleFor forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];

					datePickerView.tag = TAG_PICKER_DATE;
					if (self.apost.dateCreated)
						datePickerView.date = self.apost.dateCreated;
					else
						datePickerView.date = [NSDate date];            
					[self showPicker:datePickerView];
					break;

				default:
					break;
			}
			break;
        case 2:
        {
            if( [formatsList count] == 0 ) break;
            
            [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedPostFormat forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
            
            NSArray *titles = self.post.blog.sortedPostFormatNames;
            NSDictionary *postFormatsDict = @{
                                            @"DefaultValue": NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                                            @"Title" : NSLocalizedString(@"Visiblity", nil),
                                            @"Titles" : titles,
                                            @"Values" : titles,
                                            @"CurrentValue" : self.post.postFormatText
                                            };
            
            PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:postFormatsDict];
            __weak PostSettingsSelectionViewController *weakVc = vc;
            vc.onItemSelected = ^(NSString *status) {
                [weakVc dismiss];
                self.post.postFormatText = status;
                [tableView reloadData];
            };
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
		case 3:
            if (blogSupportsFeaturedImage) {
                UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
                switch (indexPath.row) {
                    case 0:
                        if (!self.post.post_thumbnail) {
                            [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailSettingsClickedSetFeaturedImage]];
                            if (IS_IOS7) {
                                [self showPhotoPickerForRect:cell.frame];
                            } else {
                                [self.postDetailViewController.postMediaViewController showPhotoPickerActionSheet:cell fromRect:cell.frame isFeaturedImage:YES];                                
                            }
                        }
                        break;
                    case 1:
                        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailSettingsClickedRemoveFeaturedImage]];
                        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Remove this Featured Image?", @"Prompt when removing a featured image from a post") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", "Cancel a prompt") destructiveButtonTitle:NSLocalizedString(@"Remove", @"Remove an image/posts/etc") otherButtonTitles:nil];
                        [actionSheet showFromRect:cell.frame inView:self.view animated:YES];
                        break;
                }
            } else {
                [self geolocationCellTapped:indexPath];
            }
            break;
          case 4:
            [self geolocationCellTapped:indexPath];
            break;
	}
    [aTableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

- (void)geolocationCellTapped:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            
            if(!self.post.blog.geolocationEnabled) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enable Geotagging", @"Title of an alert view stating the user needs to turn on geotagging.")
                                                                    message:NSLocalizedString(@"Geotagging is turned off. \nTo update this post's location, please enable geotagging in this blog's settings.", @"Message of an alert explaining that geotagging need to be enabled.")
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
            
            // If location services are disabled at the app level [CLLocationManager locationServicesEnabled] will be true, but the location will be nil.
            if(![CLLocationManager locationServicesEnabled] || [locationManager location] == nil) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Unavailable", @"Title of an alert view stating that the user's location is unavailable.")
                                                                    message:NSLocalizedString(@"Location Services are turned off. \nTo add or update this post's location, please enable Location Services in the Settings app.", @"Message of an alert explaining that location services need to be enabled.")
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }

            if (!isUpdatingLocation) {
                if (self.post.geolocation) {
                    [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailSettingsClickedUpdateLocation]];
                } else {
                    [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailSettingsClickedAddLocation]];
                }
                // Add or replace geotag
                isUpdatingLocation = YES;
                [locationManager startUpdatingLocation];
            }
            break;
        case 2:
            [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsEventPostDetailSettingsClickedRemoveLocation]];

            if (isUpdatingLocation) {
                // Cancel update
                isUpdatingLocation = NO;
                [locationManager stopUpdatingLocation];
            }
            self.post.geolocation = nil;
            postDetailViewController.hasLocation.enabled = NO;
            [postDetailViewController refreshButtons];
            break;
    }
    [tableView reloadData];
}

- (void)featuredImageUploadFailed: (NSNotification *)notificationInfo {
    isUploadingFeaturedImage = NO;
    [featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [featuredImageSpinner stopAnimating];
    [featuredImageSpinner setHidden:YES];
    [featuredImageView setHidden:NO];
    [tableView reloadData];
    //The code that shows the error message is available in the failure block in PostMediaViewController.
}

- (void)featuredImageUploadSucceeded: (NSNotification *)notificationInfo {
    isUploadingFeaturedImage = NO;
    Media *media = (Media *)[notificationInfo object];
    if (media) {
        [featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [featuredImageSpinner stopAnimating];
        [featuredImageSpinner setHidden:YES];
        [featuredImageLabel setHidden:YES];
        [featuredImageView setHidden:NO];
        if (![self.post isDeleted] && [self.post managedObjectContext]) {
            self.post.post_thumbnail = media.mediaID;
        }
        [featuredImageView setImage:[UIImage imageWithContentsOfFile:media.localURL]];
    } else {
        //reset buttons
    }
    [postDetailViewController refreshButtons];
    [tableView reloadData];
}

- (void)showFeaturedImageUploader:(NSNotification *)notificationInfo {
    isUploadingFeaturedImage = YES;
    [featuredImageView setHidden:YES];
    [featuredImageLabel setHidden:NO];
    [featuredImageLabel setText:NSLocalizedString(@"Uploading Image", @"Uploading a featured image in post settings")];
    [featuredImageSpinner setHidden:NO];
    if (!featuredImageSpinner.isAnimating)
        [featuredImageSpinner startAnimating];
    [tableView reloadData];
}

- (NSString *)formattedStatEventString:(NSString *)event
{
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

#pragma mark -
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)acSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (acSheet.tag == TAG_ACTIONSHEET_PHOTO) {
        [self processPhotoTypeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else if (acSheet.tag == TAG_ACTIONSHEET_RESIZE_PHOTO) {
        [self processPhotoResizeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else {
        if (buttonIndex == 0) {
            [featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            self.post.post_thumbnail = nil;
            [postDetailViewController refreshButtons];
            [tableView reloadData];
        }
    }
}

- (void)processPhotoTypeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [acSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Photo from Library", nil)]) {
        [self pickPhotoFromLibrary:self.view.bounds];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
        [self pickPhotoFromCamera:self.view.bounds];
    }
}

- (void)processPhotoResizeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            if (acSheet.numberOfButtons == 2)
                [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
            else
                [self useImage:[self resizeImage:_currentImage toSize:kResizeSmall]];
            break;
        case 1:
            if (acSheet.numberOfButtons == 2)
                [self showCustomSizeAlert];
            else if (acSheet.numberOfButtons == 3)
                [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
            else
                [self useImage:[self resizeImage:_currentImage toSize:kResizeMedium]];
            break;
        case 2:
            if (acSheet.numberOfButtons == 3)
                [self showCustomSizeAlert];
            else if (acSheet.numberOfButtons == 4)
                [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
            else
                [self useImage:[self resizeImage:_currentImage toSize:kResizeLarge]];
            break;
        case 3:
            if (acSheet.numberOfButtons == 4)
                [self showCustomSizeAlert];
            else
                [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
            break;
        case 4:
            [self showCustomSizeAlert];
            break;
    }
    
    _isShowingResizeActionSheet = NO;
}


- (void)showCustomSizeAlert {
	if(_isShowingCustomSizeAlert || _customSizeAlert != nil)
        return;
    
    _isShowingCustomSizeAlert = YES;
    
    UITextField *textWidth, *textHeight;
    UILabel *labelWidth, *labelHeight;
    
    NSString *lineBreaks;
    
    if (IS_IPAD)
        lineBreaks = @"\n\n\n\n";
    else
        lineBreaks = @"\n\n\n";
    
    
    _customSizeAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Custom Size", @"")
                                                 message:lineBreaks // IMPORTANT
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                       otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    
    labelWidth = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 50.0, 125.0, 25.0)];
    labelWidth.backgroundColor = [UIColor clearColor];
    labelWidth.textColor = [UIColor whiteColor];
    labelWidth.text = NSLocalizedString(@"Width", @"");
    [_customSizeAlert addSubview:labelWidth];
    
    textWidth = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 80.0, 125.0, 25.0)];
    [textWidth setBackgroundColor:[UIColor whiteColor]];
    [textWidth setPlaceholder:NSLocalizedString(@"Width", @"")];
    [textWidth setKeyboardType:UIKeyboardTypeNumberPad];
    [textWidth setDelegate:self];
    [textWidth setTag:123];
    
    // Check for previous width setting
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"] != nil)
        [textWidth setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"]];
    else
        [textWidth setText:[NSString stringWithFormat:@"%d", (int)_currentImage.size.width]];
    
    [_customSizeAlert addSubview:textWidth];
    
    labelHeight = [[UILabel alloc] initWithFrame:CGRectMake(145.0, 650.0, 125.0, 25.0)];
    labelHeight.backgroundColor = [UIColor clearColor];
    labelHeight.textColor = [UIColor whiteColor];
    labelHeight.text = NSLocalizedString(@"Height", @"");
    [_customSizeAlert addSubview:labelHeight];
    
    textHeight = [[UITextField alloc] initWithFrame:CGRectMake(145.0, 80.0, 125.0, 25.0)];
    [textHeight setBackgroundColor:[UIColor whiteColor]];
    [textHeight setPlaceholder:NSLocalizedString(@"Height", @"")];
    [textHeight setDelegate:self];
    [textHeight setKeyboardType:UIKeyboardTypeNumberPad];
    [textHeight setTag:456];
    
    // Check for previous height setting
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"] != nil)
        [textHeight setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"]];
    else
        [textHeight setText:[NSString stringWithFormat:@"%d", (int)_currentImage.size.height]];
    
    [_customSizeAlert addSubview:textHeight];
    [_customSizeAlert show];
    [textWidth becomeFirstResponder];
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
    } else if (aPickerView.tag == TAG_PICKER_FORMAT) {
        return [formatsList count];
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
    } else if (aPickerView.tag == TAG_PICKER_FORMAT) {
        return [formatsList objectAtIndex:row];
    }

    return @"";
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        self.apost.statusTitle = [statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        NSString *visibility = [visibilityList objectAtIndex:row];
        if ([visibility isEqualToString:NSLocalizedString(@"Private", @"Post privacy status in the Post Editor/Settings area (compare with WP core translations).")]) {
            self.apost.status = @"private";
            self.apost.password = nil;
        } else {
            if ([self.apost.status isEqualToString:@"private"]) {
                self.apost.status = @"publish";
            }
            if ([visibility isEqualToString:NSLocalizedString(@"Password protected", @"Post password protection in the Post Editor/Settings area (compare with WP core translations).")]) {
                self.apost.password = @"";
            } else {
                self.apost.password = nil;
            }
        }
    } else if (aPickerView.tag == TAG_PICKER_FORMAT) {
        self.post.postFormatText = [formatsList objectAtIndex:row];
    }
	[postDetailViewController refreshButtons];
    [tableView reloadData];
}


#pragma mark -
#pragma mark Pickers and keyboard animations

- (void)showPicker:(UIView *)picker {
    if (isShowingKeyboard)
        [passwordTextField resignFirstResponder];

    if (IS_IPAD) {
        UIViewController *fakeController = [[UIViewController alloc] init];
        
        if (picker.tag == TAG_PICKER_DATE) {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320.0f, 256.0f);
            
            if (IS_IOS7) {
                UIButton *button = [[UIButton alloc] init];
                [button addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventTouchUpInside];
                [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
                [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
                [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")] forState:UIControlStateNormal];            [button sizeToFit];
                CGPoint buttonCenter = button.center;
                buttonCenter.x = CGRectGetMidX(picker.frame);
                button.center = buttonCenter;
                
                [fakeController.view addSubview:button];
                CGRect pickerFrame = picker.frame;
                pickerFrame.origin.y = CGRectGetMaxY(button.frame);
                picker.frame = pickerFrame;
            } else {
                UISegmentedControl *publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")]];
                publishNowButton.momentary = YES;
                publishNowButton.frame = CGRectMake(0.0f, 0.0f, 320.0f, 40.0f);
                publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
                if ([publishNowButton respondsToSelector:@selector(setTintColor:)]) {
                    publishNowButton.tintColor = postDetailViewController.toolbar.tintColor;
                }
                [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
                [fakeController.view addSubview:publishNowButton];
                CGRect frame = picker.frame;
                frame.origin.y = 40.0f;
                picker.frame = frame;
            }
        } else {
            fakeController.contentSizeForViewInPopover = CGSizeMake(320.0f, 216.0f);
        }
        
        [fakeController.view addSubview:picker];
        popover = [[UIPopoverController alloc] initWithContentViewController:fakeController];
        if ([popover respondsToSelector:@selector(popoverBackgroundViewClass)]) {
            popover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
        }
        
        CGRect popoverRect;
        if (picker.tag == TAG_PICKER_STATUS)
            popoverRect = [self.view convertRect:statusLabel.frame fromView:[statusLabel superview]];
        else if (picker.tag == TAG_PICKER_VISIBILITY)
            popoverRect = [self.view convertRect:visibilityLabel.frame fromView:[visibilityLabel superview]];
        else if (picker.tag == TAG_PICKER_FORMAT)
            popoverRect = [self.view convertRect:postFormatLabel.frame fromView:[postFormatLabel superview]];
        else 
            popoverRect = [self.view convertRect:publishOnDateLabel.frame fromView:[publishOnDateLabel superview]];

        popoverRect.size.width = 100.0f;
        [popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        CGFloat width = postDetailViewController.view.frame.size.width;
        CGFloat height = 0.0;
        
        // Refactor this class to not use UIActionSheets for display. See trac #1509.
        // <rant>Shoehorning a UIPicker inside a UIActionSheet is just madness.</rant>
        // For now, hardcoding height values for the iPhone so we don't get
        // a funky gap at the bottom of the screen on the iPhone 5.
        if(postDetailViewController.view.frame.size.height <= 416.0f) {
            height = 490.0f;
        } else {
            height = 500.0f;
        }
        if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
            height = 460.0f; // Show most of the actionsheet but keep the top of the view visible.
        }
        
        UIView *pickerWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 260.0f)]; // 216 + 44 (height of the picker and the "tooblar")
        pickerWrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [pickerWrapperView addSubview:picker];
                
        CGRect pickerFrame = picker.frame;
        pickerFrame.size.width = width;
        picker.frame = pickerFrame;
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleAutomatic];
        [actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)];
        
        [actionSheet addSubview:pickerWrapperView];
        
        UISegmentedControl *closeButton;
        if (IS_IOS7) {
            UIButton *button = [[UIButton alloc] init];
            [button addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Done", @"Default main action button for closing/finishing a work flow in the app (used in Comments>Edit, Comment edits and replies, post editor body text, etc, to dismiss keyboard).")] forState:UIControlStateNormal];
            [button sizeToFit];
            CGRect frame = button.frame;
            frame.origin.x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(button.frame) - 10;
            frame.origin.y = 7;
            button.frame = frame;
            [pickerWrapperView addSubview:button];
        } else {
            closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Done", @"Default main action button for closing/finishing a work flow in the app (used in Comments>Edit, Comment edits and replies, post editor body text, etc, to dismiss keyboard).")]];
            closeButton.momentary = YES;
            CGFloat x = self.view.frame.size.width - 60.0f;
            closeButton.frame = CGRectMake(x, 7.0f, 50.0f, 30.0f);
            closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
            if ([closeButton respondsToSelector:@selector(setTintColor:)]) {
                closeButton.tintColor = [UIColor blackColor];
            }
            [closeButton addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventValueChanged];
            closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [pickerWrapperView addSubview:closeButton];
        }
        
        UISegmentedControl *publishNowButton = nil;
        if (IS_IOS7) {
            UIButton *button = [[UIButton alloc] init];
            [button addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-iOS7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")] forState:UIControlStateNormal];
            [button sizeToFit];
            CGRect frame = button.frame;
            frame.origin.x = 10;
            frame.origin.y = 7;
            button.frame = frame;
            [pickerWrapperView addSubview:button];
        } else {
            if (picker.tag == TAG_PICKER_DATE) {
                publishNowButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")]];
                publishNowButton.momentary = YES;
                publishNowButton.frame = CGRectMake(10.0f, 7.0f, 129.0f, 30.0f);
                publishNowButton.segmentedControlStyle = UISegmentedControlStyleBar;
                publishNowButton.tintColor = [UIColor blackColor];
                [publishNowButton addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventValueChanged];
                [pickerWrapperView addSubview:publishNowButton];
            }
        }
        
        if (!IS_IOS7) {
            // Since we're requiring a black tint we do not want to use the custom text colors.
            NSDictionary *titleTextAttributesForStateNormal = [NSDictionary dictionaryWithObjectsAndKeys:
                                                               [UIColor whiteColor],
                                                               UITextAttributeTextColor,
                                                               [UIColor darkGrayColor],
                                                               UITextAttributeTextShadowColor,
                                                               [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                               UITextAttributeTextShadowOffset,
                                                               nil];
            
            // The UISegmentControl does not show a pressed state for its button so (for now) use the same
            // state for normal and highlighted.
            // It would be nice to refactor this to use a toolbar and buttons instead of a segmented control to get the
            // correct look and feel.
            [closeButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
            [closeButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateHighlighted];
            
            if (publishNowButton) {
                [publishNowButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
                [publishNowButton setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateHighlighted];
            }
        }
        
        if (IS_IOS7) {
            [actionSheet showInView:self.view];
        } else {
            [actionSheet showInView:postDetailViewController.view];
        }
        [actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)]; // Update the bounds again now that its in the view else it won't draw correctly.
    }
}

- (void)hidePicker {
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
     actionSheet = nil;
}

- (void)removeDate {
    datePickerView.date = [NSDate date];
    self.apost.dateCreated = nil;
    [tableView reloadData];
    if (IS_IPAD)
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
		self.post.geolocation = c;
		postDetailViewController.hasLocation.enabled = YES;
        WPLog(@"Added geotag (%+.6f, %+.6f)",
			  c.latitude,
			  c.longitude);
		[locationManager stopUpdatingLocation];
        [postDetailViewController refreshButtons];
		[tableView reloadData];
		
		[self geocodeCoordinate:c.coordinate];

    }
    // else skip the event and process the next one.
}

#pragma mark - CLGecocoder wrapper

- (void)geocodeCoordinate:(CLLocationCoordinate2D)c {
	if (reverseGeocoder) {
		if (reverseGeocoder.geocoding)
			[reverseGeocoder cancelGeocode];
	}
    reverseGeocoder = [[CLGeocoder alloc] init];
    [reverseGeocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:c.latitude longitude:c.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            if (placemark.subLocality) {
                address = [NSString stringWithFormat:@"%@, %@, %@", placemark.subLocality, placemark.locality, placemark.country];
            } else {
                address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
            }
            addressLabel.text = address;
        } else {
            NSLog(@"Reverse geocoder failed for coordinate (%.6f, %.6f): %@",
                  c.latitude,
                  c.longitude,
                  [error localizedDescription]);
            
            address = [NSString stringWithString:NSLocalizedString(@"Location unknown", @"Used when geo-tagging posts, if the geo-tagging failed.")];
            addressLabel.text = address;
        }
    }];
}

#pragma mark - Featured Image Selection related methods
// TODO: Remove duplication with these methods and PostMediaViewController
- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];

    if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    _currentImage = image;
    
    //UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id=1000000050&ext=JPG").
    NSURL *assetURL = nil;
    if (&UIImagePickerControllerReferenceURL != NULL) {
        assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    }
    if (assetURL) {
        [self getMetadataFromAssetForURL:assetURL];
    } else {
        NSDictionary *metadata = nil;
        if (&UIImagePickerControllerMediaMetadata != NULL) {
            metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
        }
        if (metadata) {
            NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
            NSDictionary *gpsData = [mutableMetadata objectForKey:@"{GPS}"];
            if (!gpsData && self.post.geolocation) {
                /*
                 Sample GPS data dictionary
                 "{GPS}" =     {
                 Altitude = 188;
                 AltitudeRef = 0;
                 ImgDirection = "84.19556";
                 ImgDirectionRef = T;
                 Latitude = "41.01333333333333";
                 LatitudeRef = N;
                 Longitude = "0.01666666666666";
                 LongitudeRef = W;
                 TimeStamp = "10:34:04.00";
                 };
                 */
                CLLocationDegrees latitude = self.post.geolocation.latitude;
                CLLocationDegrees longitude = self.post.geolocation.longitude;
                NSDictionary *gps = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithDouble:fabs(latitude)], @"Latitude",
                                     (latitude < 0.0) ? @"S" : @"N", @"LatitudeRef",
                                     [NSNumber numberWithDouble:fabs(longitude)], @"Longitude",
                                     (longitude < 0.0) ? @"W" : @"E", @"LongitudeRef",
                                     nil];
                [mutableMetadata setObject:gps forKey:@"{GPS}"];
            }
            [mutableMetadata removeObjectForKey:@"Orientation"];
            [mutableMetadata removeObjectForKey:@"{TIFF}"];
            _currentImageMetadata = mutableMetadata;
        }
    }
    
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *resizePreference = [NSNumber numberWithInt:-1];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
        resizePreference = [nf numberFromString:[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]];
    BOOL showResizeActionSheet;
    switch ([resizePreference intValue]) {
        case 0:
        {
            // Dispatch async to detal with a rare bug presenting the actionsheet after a memory warning when the
            // view has been recreated.
            showResizeActionSheet = true;
            break;
        }
        case 1:
        {
            [self useImage:[self resizeImage:_currentImage toSize:kResizeSmall]];
            break;
        }
        case 2:
        {
            [self useImage:[self resizeImage:_currentImage toSize:kResizeMedium]];
            break;
        }
        case 3:
        {
            [self useImage:[self resizeImage:_currentImage toSize:kResizeLarge]];
            break;
        }
        case 4:
        {
            //[self useImage:currentImage];
            [self useImage:[self resizeImage:_currentImage toSize:kResizeOriginal]];
            break;
        }
        default:
        {
            showResizeActionSheet = true;
            break;
        }
    }
    
    if(IS_IPAD) {
        [popover dismissPopoverAnimated:YES];
        if (showResizeActionSheet) {
            [self showResizeActionSheet];
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            if (showResizeActionSheet) {
                [self showResizeActionSheet];
            }
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
 * Take Asset URL and set imageJPEG property to NSData containing the
 * associated JPEG, including the metadata we're after.
 */
-(void)getMetadataFromAssetForURL:(NSURL *)url {
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:url
				   resultBlock: ^(ALAsset *myasset) {
					   ALAssetRepresentation *rep = [myasset defaultRepresentation];
					   
					   WPLog(@"getJPEGFromAssetForURL: default asset representation for %@: uti: %@ size: %lld url: %@ orientation: %d scale: %f metadata: %@",
							 url, [rep UTI], [rep size], [rep url], [rep orientation],
							 [rep scale], [rep metadata]);
					   
					   Byte *buf = malloc([rep size]);  // will be freed automatically when associated NSData is deallocated
					   NSError *err = nil;
					   NSUInteger bytes = [rep getBytes:buf fromOffset:0LL
												 length:[rep size] error:&err];
					   if (err || bytes == 0) {
						   // Are err and bytes == 0 redundant? Doc says 0 return means
						   // error occurred which presumably means NSError is returned.
						   free(buf); // Free up memory so we don't leak.
						   WPLog(@"error from getBytes: %@", err);
						   
						   return;
					   }
					   NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf length:[rep size]
														  freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
					   
					   CGImageSourceRef  source ;
					   source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, NULL);
					   
                       NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                       
                       //make the metadata dictionary mutable so we can remove properties to it
                       NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
                       
					   if(!self.apost.blog.geolocationEnabled) {
						   //we should remove the GPS info if the blog has the geolocation set to off
						   
						   //get all the metadata in the image
						   [metadataAsMutable removeObjectForKey:@"{GPS}"];
					   }
                       [metadataAsMutable removeObjectForKey:@"Orientation"];
                       [metadataAsMutable removeObjectForKey:@"{TIFF}"];
                       _currentImageMetadata = [NSDictionary dictionaryWithDictionary:metadataAsMutable];
					   
					   CFRelease(source);
				   }
				  failureBlock: ^(NSError *err) {
					  WPLog(@"can't get asset %@: %@", url, err);
					  _currentImageMetadata = nil;
				  }];
}

- (UIImage *)resizeImage:(UIImage *)original toSize:(MediaResize)resize {
    NSDictionary* predefDim = [self.apost.blog getImageResizeDimensions];
    CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
    CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
    CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
    switch (original.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            smallSize = CGSizeMake(smallSize.height, smallSize.width);
            mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
            largeSize = CGSizeMake(largeSize.height, largeSize.width);
            break;
        default:
            break;
    }
    
    CGSize originalSize = CGSizeMake(original.size.width, original.size.height); //The dimensions of the image, taking orientation into account.
	
	// Resize the image using the selected dimensions
	UIImage *resizedImage = original;
	switch (resize) {
		case kResizeSmall:
			if(original.size.width > smallSize.width  || original.size.height > smallSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:smallSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
			break;
		case kResizeMedium:
			if(original.size.width > mediumSize.width  || original.size.height > mediumSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:mediumSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
			break;
		case kResizeLarge:
			if(original.size.width > largeSize.width || original.size.height > largeSize.height) {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:largeSize
												interpolationQuality:kCGInterpolationHigh];
            } else {
				resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
															  bounds:originalSize
												interpolationQuality:kCGInterpolationHigh];
            }
			break;
		case kResizeOriginal:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
														  bounds:originalSize
											interpolationQuality:kCGInterpolationHigh];
			break;
	}
    
	return resizedImage;
}

- (void)useImage:(UIImage *)theImage {
	Media *imageMedia = [Media newMediaForPost:self.apost];
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
    
	if (_currentImageMetadata != nil) {
		// Write the EXIF data with the image data to disk
		CGImageSourceRef  source = NULL;
        CGImageDestinationRef destination = NULL;
		BOOL success = NO;
        //this will be the data CGImageDestinationRef will write into
        NSMutableData *dest_data = [NSMutableData data];
        
		source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
            
            if(destination) {
                //add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) _currentImageMetadata);
                
                //tell the destination to write the image data and metadata into our data object.
                //It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
            } else {
                WPFLog(@"***Could not create image destination ***");
            }
        } else {
            WPFLog(@"***Could not create image source ***");
        }
		
		if(!success) {
			WPLog(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
		}
		//cleanup
        if (destination) {
            CFRelease(destination);
        }
        if (source) {
            CFRelease(source);
        }
    } else {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
	}
    
	if([self interpretOrientation] == kLandscape) {
		imageMedia.orientation = @"landscape";
    } else {
		imageMedia.orientation = @"portrait";
    }
	imageMedia.creationDate = [NSDate date];
	imageMedia.filename = filename;
	imageMedia.localURL = filepath;
	imageMedia.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
    imageMedia.mediaType = @"featured";
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadingFeaturedImage" object:nil];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            NSLog(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        [WPError showAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
    }];
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (MediaOrientation)interpretOrientation {
	MediaOrientation result = kPortrait;
	switch ([[UIDevice currentDevice] orientation]) {
		case UIDeviceOrientationPortrait:
			result = kPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			result = kPortrait;
			break;
		case UIDeviceOrientationLandscapeLeft:
			result = kLandscape;
			break;
		case UIDeviceOrientationLandscapeRight:
			result = kLandscape;
			break;
		case UIDeviceOrientationFaceUp:
			result = kPortrait;
			break;
		case UIDeviceOrientationFaceDown:
			result = kPortrait;
			break;
		case UIDeviceOrientationUnknown:
			result = kPortrait;
			break;
	}
	
	return result;
}

- (void)showResizeActionSheet {
	if(_isShowingResizeActionSheet == NO) {
		_isShowingResizeActionSheet = YES;
        
        Blog *currentBlog = self.apost.blog;
        NSDictionary* predefDim = [currentBlog getImageResizeDimensions];
        CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
        CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
        CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
        CGSize originalSize = CGSizeMake(_currentImage.size.width, _currentImage.size.height); //The dimensions of the image, taking orientation into account.
        
        switch (_currentImage.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                smallSize = CGSizeMake(smallSize.height, smallSize.width);
                mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
                largeSize = CGSizeMake(largeSize.height, largeSize.width);
                break;
            default:
                break;
        }
        
		NSString *resizeSmallStr = [NSString stringWithFormat:NSLocalizedString(@"Small (%@)", @"Small (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)smallSize.width, (int)smallSize.height]];
   		NSString *resizeMediumStr = [NSString stringWithFormat:NSLocalizedString(@"Medium (%@)", @"Medium (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)mediumSize.width, (int)mediumSize.height]];
        NSString *resizeLargeStr = [NSString stringWithFormat:NSLocalizedString(@"Large (%@)", @"Large (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)largeSize.width, (int)largeSize.height]];
        NSString *originalSizeStr = [NSString stringWithFormat:NSLocalizedString(@"Original (%@)", @"Original (width x height)"), [NSString stringWithFormat:@"%ix%i", (int)originalSize.width, (int)originalSize.height]];
        
		UIActionSheet *resizeActionSheet;
		//NSLog(@"img dimension: %f x %f ",_currentImage.size.width, _currentImage.size.height );
		
		if(_currentImage.size.width > largeSize.width  && _currentImage.size.height > largeSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, resizeLargeStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > mediumSize.width  && _currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > smallSize.width  && _currentImage.size.height > smallSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles: originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
		}
		
        resizeActionSheet.tag = TAG_ACTIONSHEET_RESIZE_PHOTO;
        [resizeActionSheet showInView:self.view];
	}
}




#pragma mark - Private Methods

- (NSString *)titleForVisibility
{
    if (self.apost.password) {
        return NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP.");
    } else if ([self.apost.status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.");
    } else {
        return NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP.");
    }
}

- (void)showPhotoPickerForRect:(CGRect)frame
{
    UIActionSheet *photoActionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		photoActionSheet = [[UIActionSheet alloc] initWithTitle:@""
												  delegate:self
										 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
									destructiveButtonTitle:nil
										 otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];
        photoActionSheet.tag = TAG_ACTIONSHEET_PHOTO;
        photoActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [photoActionSheet showFromRect:frame inView:self.view animated:YES];
	}
	else {
        [self pickPhotoFromLibrary:frame];
	}
}

- (void)pickPhotoFromLibrary:(CGRect)frame
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    
    if (IS_IPAD) {
        popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        popover.delegate = self;
        [popover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [[CPopoverManager instance] setCurrentPopoverController:popover];
    } else {
        [self.navigationController presentViewController:picker animated:YES completion:nil];
    }
}

- (void)pickPhotoFromCamera:(CGRect)frame
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    
    if (IS_IPAD) {
        popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        popover.delegate = self;
        [popover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [[CPopoverManager instance] setCurrentPopoverController:popover];
    } else {
        [self.navigationController presentViewController:picker animated:YES completion:nil];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)dismissTagsKeyboardIfAppropriate:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:tableView];
    if (!CGRectContainsPoint(tagsTextField.frame, touchPoint) && [tagsTextField isFirstResponder]) {
        [tagsTextField resignFirstResponder];
    }
}

#pragma mark - Categories Related

- (void)showCategoriesSelectionView:(CGRect)cellFrame
{
    [self populateSelectionsControllerWithCategories:cellFrame];
}

- (void)populateSelectionsControllerWithCategories:(CGRect)cellFrame
{
    WPFLogMethod();
    if (_segmentedTableViewController == nil) {
        _segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc]
                                        initWithNibName:@"WPSelectionTableViewController"
                                        bundle:nil];
    }
    
    NSArray *cats = [self.post.blog sortedCategories];
    NSArray *selObject = [self.post.categories allObjects];
    
    [_segmentedTableViewController populateDataSource:cats    //datasource
                                       havingContext:kSelectionsCategoriesContext
                                     selectedObjects:selObject
                                       selectionType:kCheckbox
                                         andDelegate:self];
    
    _segmentedTableViewController.title = NSLocalizedString(@"Categories", @"");
    UIBarButtonItem *createCategoryBarButtonItem;

    createCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-add"]
                                                                   style:[WPStyleGuide barButtonStyleForBordered]
                                                                  target:self
                                                                  action:@selector(showAddNewCategoryView:)];    
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:createCategoryBarButtonItem forNavigationItem:_segmentedTableViewController.navigationItem];
    
    
    if (!_isNewCategory) {
        if (IS_IPAD == YES) {
            UINavigationController *navController;
            if (_segmentedTableViewController.navigationController) {
                navController = _segmentedTableViewController.navigationController;
            } else {
                navController = [[UINavigationController alloc] initWithRootViewController:_segmentedTableViewController];
            }
            navController.navigationBar.translucent = NO;
            UIPopoverController *categoriesPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
            if ([categoriesPopover respondsToSelector:@selector(popoverBackgroundViewClass)]) {
                categoriesPopover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
            }
            categoriesPopover.delegate = self;
            CGRect popoverRect = cellFrame;
            categoriesPopover.popoverContentSize = CGSizeMake(320.0f, 460.0f);
            [categoriesPopover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [[CPopoverManager instance] setCurrentPopoverController:categoriesPopover];
            
        } else {
            [self.navigationController pushViewController:_segmentedTableViewController animated:YES];
        }
    }
    
    _isNewCategory = NO;
}

- (IBAction)showAddNewCategoryView:(id)sender
{
    WPFLogMethod();
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
    addCategoryViewController.blog = self.post.blog;
	if (IS_IPAD == YES) {
        [_segmentedTableViewController pushViewController:addCategoryViewController animated:YES];
 	} else {
		UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
        nc.navigationBar.translucent = NO;
        [_segmentedTableViewController presentViewController:nc animated:YES completion:nil];
	}
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        return;
    }
    
    if (selContext == kSelectionsCategoriesContext) {
        NSMutableSet *categories = [self.post mutableSetValueForKey:@"categories"];
        [categories removeAllObjects];
        [categories addObjectsFromArray:selectedObjects];
        [tableView reloadData];
    }
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification {
    WPFLogMethod();
    if ([_segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        _isNewCategory = YES;
        [self populateSelectionsControllerWithCategories:CGRectZero];
    }
}


@end

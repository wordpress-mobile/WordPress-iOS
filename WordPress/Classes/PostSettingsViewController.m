#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "EditPostViewController_Internal.h"
#import "PostSettingsSelectionViewController.h"
#import "NSString+XMLExtensions.h"
#import <ImageIO/ImageIO.h>
#import "WPSegmentedSelectionTableViewController.h"
#import "WPAddCategoryViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "Post.h"
#import "UITableViewTextFieldCell.h"
#import "WPAlertView.h"

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)
#define kPasswordFooterSectionHeight        68.0f
#define kResizePhotoSettingSectionHeight    60.0f
#define TAG_PICKER_STATUS                   0
#define TAG_PICKER_VISIBILITY               1
#define TAG_PICKER_DATE                     2
#define TAG_PICKER_FORMAT                   3
#define TAG_ACTIONSHEET_PHOTO               10
#define TAG_ACTIONSHEET_RESIZE_PHOTO        20
#define kOFFSET_FOR_KEYBOARD                150.0

static NSString *const LocationServicesCellIdentifier = @"LocationServicesCellIdentifier";
static NSString *const TableViewActivityCellIdentifier = @"TableViewActivityCellIdentifier";
static NSString *const RemoveGeotagCellIdentifier = @"RemoveGeotagCellIdentifier";

@interface PostSettingsViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                          UIPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL triedAuthOnce;
@property (nonatomic, assign) BOOL isNewCategory;
@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, assign) BOOL isShowingResizeActionSheet;
@property (nonatomic, assign) BOOL isShowingCustomSizeAlert;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) WPAlertView *customSizeAlert;

// Post tags, status
@property (nonatomic, strong) IBOutlet WPTableViewCell *visibilityTableViewCell;
@property (nonatomic, strong) IBOutlet UILabel *visibilityLabel;
@property (nonatomic, strong) IBOutlet UILabel *postFormatLabel;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) IBOutlet UITableViewCell *postFormatTableViewCell;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *publishOnDateLabel;
@property (nonatomic, strong) UITextField *tagsTextField;
@property (nonatomic, strong) NSArray *statusList;
@property (nonatomic, strong) NSArray *visibilityList;
@property (nonatomic, strong) NSArray *formatsList;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIDatePicker *datePickerView;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, assign) BOOL isShowingKeyboard, blogSupportsFeaturedImage;

// Geotagging
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UILabel *coordinateLabel;
@property (nonatomic, strong) IBOutlet UITableViewCell *mapGeotagTableViewCell;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *reverseGeocoder;
@property (nonatomic, strong) PostAnnotation *annotation;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) BOOL isUpdatingLocation, isUploadingFeaturedImage;

// Featured image
@property (nonatomic, strong) IBOutlet UILabel *visibilityTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *featuredImageLabel;
@property (nonatomic, strong) IBOutlet UIImageView *featuredImageView;
@property (nonatomic, strong) IBOutlet WPTableViewActivityCell *featuredImageTableViewCell;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *featuredImageSpinner;

@end

@implementation PostSettingsViewController

- (void)dealloc {
	if (_locationManager) {
		_locationManager.delegate = nil;
		[_locationManager stopUpdatingLocation];
	}
	if (_reverseGeocoder) {
		[_reverseGeocoder cancelGeocode];
	}
	_mapView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super init];
    if (self) {
        _apost = aPost;
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
    self.title = NSLocalizedString(@"Options", nil);

    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFeaturedImageUploader:) name:@"UploadingFeaturedImage" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadSucceeded:) name:FeaturedImageUploadSuccessfulNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageUploadFailed:) name:FeaturedImageUploadFailedNotification object:nil];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    self.visibilityTitleLabel.text = NSLocalizedString(@"Visibility", @"The visibility settings of the post. Should be the same as in core WP.");
    self.passwordTextField.placeholder = NSLocalizedString(@"Enter a password", @"");
    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[self.apost availableStatuses]];
    [allStatuses removeObject:NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    self.statusList = [NSArray arrayWithArray:allStatuses];
    self.visibilityList = [NSArray arrayWithObjects:NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."), NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."), NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP."), nil];
    self.formatsList = self.post.blog.sortedPostFormatNames;

    self.isShowingKeyboard = NO;

    CGRect pickerFrame;
	if (IS_IPAD) {
		pickerFrame = CGRectMake(0.0f, 0.0f, 320.0f, 216.0f);
    } else {
		pickerFrame = CGRectMake(0.0f, 44.0f, 320.0f, 216.0f);
    }

    self.pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.showsSelectionIndicator = YES;

    self.datePickerView = [[UIDatePicker alloc] initWithFrame:self.pickerView.frame];
    self.datePickerView.minuteInterval = 5;
    [self.datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];

    self.passwordTextField.returnKeyType = UIReturnKeyDone;
	self.passwordTextField.delegate = self;

    // Automatically update the location for a new post
    BOOL isNewPost = (self.apost.remoteStatus == AbstractPostRemoteStatusLocal) && !self.post.geolocation;
    BOOL postAllowsGeotag = self.post && self.post.blog.geolocationEnabled;
	if (isNewPost && postAllowsGeotag && [CLLocationManager locationServicesEnabled]) {
        self.isUpdatingLocation = YES;
        [self.locationManager startUpdatingLocation];
	}

    self.featuredImageView.layer.shadowOffset = CGSizeMake(0.0, 1.0f);
    self.featuredImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.featuredImageView.layer.shadowOpacity = 0.5f;
    self.featuredImageView.layer.shadowRadius = 1.0f;

    self.featuredImageLabel.font = [WPStyleGuide tableviewTextFont];
    self.featuredImageLabel.textColor = [WPStyleGuide whisperGrey];

    // Check if blog supports featured images
    id supportsFeaturedImages = [self.post.blog getOptionValue:@"post_thumbnail"];
    if (supportsFeaturedImages) {
        self.blogSupportsFeaturedImage = [supportsFeaturedImages boolValue];

        if (self.blogSupportsFeaturedImage && [self.post.media count] > 0) {
            for (Media *media in self.post.media) {
                NSInteger status = [media.remoteStatusNumber integerValue];
                if ([media.mediaType isEqualToString:@"featured"] && (status == MediaRemoteStatusPushing || status == MediaRemoteStatusProcessing)){
                    [self showFeaturedImageUploader:nil];
                }
            }
        }

        if (!self.isUploadingFeaturedImage && (self.blogSupportsFeaturedImage && self.post.post_thumbnail != nil)) {
            // Download the current featured image
            [self.featuredImageView setHidden:YES];
            [self.featuredImageLabel setText:NSLocalizedString(@"Loading Featured Image", @"Loading featured image in post settings")];
            [self.featuredImageLabel setHidden:NO];
            [self.featuredImageSpinner setHidden:NO];
            if (!self.featuredImageSpinner.isAnimating) {
                [self.featuredImageSpinner startAnimating];
            }
            [self.tableView reloadData];

            [self.post getFeaturedImageURLWithSuccess:^{
                if (self.post.featuredImageURL) {
                    NSURL *imageURL = [[NSURL alloc] initWithString:self.post.featuredImageURL];
                    if (imageURL) {
                        [self.featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
                        [self loadFeaturedImage:imageURL];
                    }
                }
            } failure:^(NSError *error) {
                [self.featuredImageView setHidden:YES];
                [self.featuredImageSpinner stopAnimating];
                [self.featuredImageSpinner setHidden:YES];
                [self.featuredImageLabel setText:NSLocalizedString(@"Could not download Featured Image.", @"Featured image could not be downloaded for display in post settings.")];
            }];
        }
    }

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTagsKeyboardIfAppropriate:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:LocationServicesCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:RemoveGeotagCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"WPTableViewActivityCell" bundle:nil] forCellReuseIdentifier:TableViewActivityCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.apost.managedObjectContext performBlock:^{
        [self.apost.managedObjectContext save:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];

    self.mapView = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}

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
        [self.featuredImageView setImage:responseObject];
        [self.featuredImageView setHidden:NO];
        [self.featuredImageSpinner stopAnimating];
        [self.featuredImageSpinner setHidden:YES];
        [self.featuredImageLabel setHidden:YES];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // private blog, auth needed.
        if (operation.response.statusCode == 403) {
            if (!self.triedAuthOnce) {
                self.triedAuthOnce = YES;

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
        [self.featuredImageView setHidden:YES];
        [self.featuredImageSpinner stopAnimating];
        [self.featuredImageSpinner setHidden:YES];
        [self.featuredImageLabel setText:NSLocalizedString(@"Could not download Featured Image.", @"Featured image could not be downloaded for display in post settings.")];
    }];

    [operation start];
}


- (void)endEditingAction:(id)sender {
	if (self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
	}
}

- (void)endEditingForTextFieldAction:(id)sender {
    [self.passwordTextField endEditing:YES];
}

- (void)reloadData {
    self.passwordTextField.text = self.apost.password;

    [self.tableView reloadData];
}

- (void)datePickerChanged {
    self.apost.dateCreated = self.datePickerView.date;
    [self.tableView reloadData];
}

#pragma mark - TextField Delegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        self.apost.password = textField.text;
    } else if (textField == self.tagsTextField) {
        self.post.tags = self.tagsTextField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagsTextField) {
        self.post.tags = [self.tagsTextField.text stringByReplacingCharactersInRange:range withString:string];
    }
    return YES;
}


#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 1; // Always have the status section
	if (self.post) {
        sections += 1; // Post formats
        sections += 1; // Post Metadata
        if (self.blogSupportsFeaturedImage) {
            sections += 1;
        }
        if (self.post.blog.geolocationEnabled || self.post.geolocation) {
            sections += 1; // Geolocation
        }
	}
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.post) {
            return 2; // Post Metadata
        } else {
            return 3;
        }

    } else if (section == 1) {
		return 3;

    } else if (section == 2) {
        return 1;

    } else if (section == 3 && self.blogSupportsFeaturedImage) {
        if (self.post.post_thumbnail && !self.isUploadingFeaturedImage) {
            return 2;
        } else {
            return 1;
        }

	} else if ((section == 3 && !self.blogSupportsFeaturedImage) || section == 4) {
		if (self.post.geolocation) {
			return 3; // Add/Update | Map | Remove
		} else {
			return 1; // Add
        }
	}
    return 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
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
    } else if ((alteredSection == 3 && self.blogSupportsFeaturedImage)) {
		return NSLocalizedString(@"Featured Image", @"Label for the Featured Image area in post settings.");
    } else if ((alteredSection == 3 && !self.blogSupportsFeaturedImage) || alteredSection == 4) {
		return NSLocalizedString(@"Geolocation", @"Label for the geolocation feature (tagging posts by their physical location).");
    } else {
		return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
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
                case 0: {
                    static NSString *CategoriesCellIdentifier = @"CategoriesCell";
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CategoriesCellIdentifier];
                    if (cell == nil) {
                        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CategoriesCellIdentifier];
                    }
                    cell.textLabel.text = NSLocalizedString(@"Categories", @"Label for the categories field. Should be the same as WP core.");
                    cell.detailTextLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    [WPStyleGuide configureTableViewCell:cell];
                    return cell;
                }
                    break;
                case 1: {
                    static NSString *TagsCellIdentifier = @"TagsCell";
                    UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TagsCellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TagsCellIdentifier];
                    }
                    cell.textLabel.text = NSLocalizedString(@"Tags", @"Label for the tags field. Should be the same as WP core.");
                    cell.textField.text = self.post.tags;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Comma separated", @"Placeholder text for the tags field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
                    cell.textField.returnKeyType = UIReturnKeyDone;
                    cell.textField.delegate = self;
                    self.tagsTextField = cell.textField;
                    [WPStyleGuide configureTableViewTextCell:cell];
                    return cell;
                }
            }
	case 1:
		switch (indexPath.row) {
			case 0: {
                static NSString *StatusCellIdentifier = @"StatusCell";
                UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:StatusCellIdentifier];
                if (cell == nil) {
                    cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:StatusCellIdentifier];
                }
                cell.textLabel.text = NSLocalizedString(@"Status", @"The status of the post. Should be the same as in core WP.");
                self.statusLabel = cell.detailTextLabel;
				if (([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)
					&& ([self.apost.status isEqualToString:@"publish"])) {
					cell.detailTextLabel.text = NSLocalizedString(@"Scheduled", @"If a post is scheduled for later, this string is used for the post's status. Should use the same translation as core WP.");
				} else {
					cell.detailTextLabel.text = self.apost.statusTitle;
				}
				if ([self.apost.status isEqualToString:@"private"]) {
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				[WPStyleGuide configureTableViewCell:cell];
				return cell;
				break;
            }
			case 1:
                self.visibilityTitleLabel.font = [WPStyleGuide tableviewTextFont];
                self.visibilityTitleLabel.textColor = [WPStyleGuide whisperGrey];
                self.visibilityLabel.font = [WPStyleGuide tableviewSubtitleFont];
                self.visibilityLabel.textColor = [WPStyleGuide whisperGrey];
				if (self.apost.password) {
					self.passwordTextField.text = self.apost.password;
					self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
				}
                self.passwordTextField.font = [WPStyleGuide tableviewTextFont];
                self.passwordTextField.textColor = [WPStyleGuide whisperGrey];

                self.visibilityLabel.text = [self titleForVisibility];

                self.visibilityTableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				return self.visibilityTableViewCell;
				break;
			case 2:
			{
                static NSString *PublishedOnCellIdentifier = @"PublishedOnCell";
                UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PublishedOnCellIdentifier];
                if (cell == nil) {
                    cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:PublishedOnCellIdentifier];
                }
                self.publishOnDateLabel = cell.detailTextLabel;
				if (self.apost.dateCreated) {
					if ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending) {
						cell.textLabel.text = NSLocalizedString(@"Scheduled for", @"Scheduled for [date]");
					} else {
						cell.textLabel.text = NSLocalizedString(@"Published on", @"Published on [date]");
					}

					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
					[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
					cell.detailTextLabel.text = [dateFormatter stringFromDate:self.apost.dateCreated];
				} else {
					cell.textLabel.text = NSLocalizedString(@"Publish   ", @""); //dorky spacing fix
					cell.detailTextLabel.text = NSLocalizedString(@"Immediately", @"");
				}
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                [WPStyleGuide configureTableViewCell:cell];
                return cell;
			}
			default:
				break;
		}
		break;
    case 2: // Post format
        {
            static NSString *PostFormatCellIdentifier = @"PostFormatCell";
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PostFormatCellIdentifier];
            if (cell == nil) {
                cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:PostFormatCellIdentifier];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Post Format", @"The post formats available for the post. Should be the same as in core WP.");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.postFormatLabel = cell.detailTextLabel;

            if ([self.formatsList count] != 0) {
                cell.detailTextLabel.text = self.post.postFormatText;
            }
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        }
	case 3:
        if (self.blogSupportsFeaturedImage) {
            if (!self.post.post_thumbnail && !self.isUploadingFeaturedImage) {
                WPTableViewActivityCell *activityCell = (WPTableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:TableViewActivityCellIdentifier forIndexPath:indexPath];
                activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;

                [WPStyleGuide configureTableViewActionCell:activityCell];
                [activityCell.textLabel setText:NSLocalizedString(@"Set Featured Image", @"")];
                return activityCell;
            } else {
                switch (indexPath.row) {
                    case 0:
                        return self.featuredImageTableViewCell;
                    case 1: {
                        WPTableViewActivityCell *activityCell = (WPTableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:TableViewActivityCellIdentifier forIndexPath:indexPath];
                        [activityCell.textLabel setText: NSLocalizedString(@"Remove Featured Image", "Remove featured image from post")];
                        [WPStyleGuide configureTableViewActionCell:activityCell];
                        return activityCell;
                    }

                }
            }
        } else {
            return [self getGeolocationCellWithIndexPath:indexPath forTableView:aTableView];
        }
        break;
    case 4:
        return [self getGeolocationCellWithIndexPath:indexPath forTableView:aTableView];
        break;
	}

    return nil;
}

- (UITableViewCell*)getGeolocationCellWithIndexPath:(NSIndexPath*)indexPath forTableView:(UITableView *)tableView {
    switch (indexPath.row) {
        case 0: // Add/update location
        {
            // If location services are disabled at the app level [CLLocationManager locationServicesEnabled] will be true, but the location will be nil.
            if(!self.post.blog.geolocationEnabled) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeolocationDisabledCell"];
                if (!cell) {
                    cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GeolocationDisabledCell"];
                    cell.textLabel.text = NSLocalizedString(@"Enable Geotagging to Edit", @"Prompt the user to enable geolocation tagging on their blog.");
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    [WPStyleGuide configureTableViewActionCell:cell];
                }
                return cell;

            } else if(![CLLocationManager locationServicesEnabled] || [self.locationManager location] == nil) {
                WPTableViewCell *cell = (WPTableViewCell *) [tableView dequeueReusableCellWithIdentifier:LocationServicesCellIdentifier forIndexPath:indexPath];
                cell.textLabel.text = NSLocalizedString(@"Please Enable Location Services", @"Prompt the user to enable location services on their device.");
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                [WPStyleGuide configureTableViewActionCell:cell];

                return cell;

            } else {
                WPTableViewActivityCell *activityCell = (WPTableViewActivityCell *)[tableView dequeueReusableCellWithIdentifier:TableViewActivityCellIdentifier forIndexPath:indexPath];
                if (self.isUpdatingLocation) {
                    activityCell.textLabel.text = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");
                    [activityCell.spinner startAnimating];
                } else {
                    [activityCell.spinner stopAnimating];
                    if (self.post.geolocation) {
                        activityCell.textLabel.text = NSLocalizedString(@"Update Location", @"Gelocation feature to update physical location.");
                    } else {
                        activityCell.textLabel.text = NSLocalizedString(@"Add Location", @"Geolocation feature to add location.");
                    }
                }
                [WPStyleGuide configureTableViewActionCell:activityCell];
                return activityCell;
            }
            break;
        }
        case 1:
        {
            DDLogVerbose(@"Reloading map");
            [self.mapView removeAnnotation:self.annotation];
            self.annotation = [[PostAnnotation alloc] initWithCoordinate:self.post.geolocation.coordinate];
            [self.mapView addAnnotation:self.annotation];
            
            if (self.addressLabel == nil) {
                self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 130, 280, 30)];
            }
            if (self.coordinateLabel == nil) {
                self.coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 162, 280, 20)];
            }
            
            // Set center of map and show a region of around 200x100 meters
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.post.geolocation.coordinate, 200, 100);
            [self.mapView setRegion:region animated:YES];
            if (self.address) {
                self.addressLabel.text = self.address;
            } else {
                self.addressLabel.text = NSLocalizedString(@"Finding address...", @"Used for Geo-tagging posts.");
                [self geocodeCoordinate:self.post.geolocation.coordinate];
            }
            self.addressLabel.font = [WPStyleGuide regularTextFont];
            self.addressLabel.textColor = [WPStyleGuide allTAllShadeGrey];
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
            
            self.coordinateLabel.text = [NSString stringWithFormat:@"%i°%i' %@, %i°%i' %@",
                                    latD, latM, latDir,
                                    lonD, lonM, lonDir];

            self.coordinateLabel.font = [WPStyleGuide regularTextFont];
            self.coordinateLabel.textColor = [WPStyleGuide allTAllShadeGrey];
            
            return self.mapGeotagTableViewCell;
        }
        case 2:
        {
            WPTableViewCell *cell = (WPTableViewCell *)[tableView dequeueReusableCellWithIdentifier:RemoveGeotagCellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Remove Location", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            [WPStyleGuide configureTableViewActionCell:cell];
            return cell;
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 1) && (indexPath.row == 1) && (self.apost.password)) {
        return 88.f;
    } else if (
             (!self.blogSupportsFeaturedImage && (indexPath.section == 3) && (indexPath.row == 1))
             || (self.blogSupportsFeaturedImage && (self.post.post_thumbnail || self.isUploadingFeaturedImage) && indexPath.section == 3 && indexPath.row == 0)
             || (self.blogSupportsFeaturedImage && (indexPath.section == 4) && (indexPath.row == 1))
               ) {
		return 188.0f;
	} else {
        return 44.0f;
    }
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
                    [self showCategoriesSelectionView:[self.tableView cellForRowAtIndexPath:indexPath].frame];
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
                        [self.apost setStatusTitle:status];
                        [weakVc dismiss];
                        [self.tableView reloadData];
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
                                                    @"Title" : NSLocalizedString(@"Visibility", nil),
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
                        
                        [self.tableView reloadData];
                    };
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
				}
				case 2:
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedScheduleFor forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];

					self.datePickerView.tag = TAG_PICKER_DATE;
					if (self.apost.dateCreated)
						self.datePickerView.date = self.apost.dateCreated;
					else
						self.datePickerView.date = [NSDate date];            
					[self showPicker:self.datePickerView];
					break;

				default:
					break;
			}
			break;
        case 2:
        {
            if( [self.formatsList count] == 0 ) break;
            
            [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedPostFormat forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
            
            NSArray *titles = self.post.blog.sortedPostFormatNames;
            NSDictionary *postFormatsDict = @{
                                            @"DefaultValue": titles[0],
                                            @"Title" : NSLocalizedString(@"Post Format", nil),
                                            @"Titles" : titles,
                                            @"Values" : titles,
                                            @"CurrentValue" : self.post.postFormatText
                                            };
            
            PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:postFormatsDict];
            __weak PostSettingsSelectionViewController *weakVc = vc;
            vc.onItemSelected = ^(NSString *status) {
                self.post.postFormatText = status;
                [weakVc dismiss];
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
		case 3:
            if (self.blogSupportsFeaturedImage) {
                UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
                switch (indexPath.row) {
                    case 0:
                        if (!self.post.post_thumbnail) {
                            [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsPropertyPostDetailSettingsClickedSetFeaturedImage]];
                            [self showPhotoPickerForRect:cell.frame];
                        }
                        break;
                    case 1:
                        [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedRemoveFeaturedImage forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                        self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Remove this Featured Image?", @"Prompt when removing a featured image from a post") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", "Cancel a prompt") destructiveButtonTitle:NSLocalizedString(@"Remove", @"Remove an image/posts/etc") otherButtonTitles:nil];
                        [self.actionSheet showFromRect:cell.frame inView:self.tableView animated:YES];
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
    [aTableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)geolocationCellTapped:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            
            if (!self.post.blog.geolocationEnabled) {
                [WPError showAlertWithTitle:NSLocalizedString(@"Enable Geotagging", @"Title of an alert view stating the user needs to turn on geotagging.")
                                    message:NSLocalizedString(@"Geotagging is turned off. \nTo update this post's location, please enable geotagging in this blog's settings.", @"Message of an alert explaining that geotagging need to be enabled.")
                          withSupportButton:NO];
                return;
            }
            
            // If location services are disabled at the app level [CLLocationManager locationServicesEnabled] will be true, but the location will be nil.
            if (![CLLocationManager locationServicesEnabled] || [self.locationManager location] == nil) {
                [WPError showAlertWithTitle:NSLocalizedString(@"Location Unavailable", @"Title of an alert view stating that the user's location is unavailable.")
                                    message:NSLocalizedString(@"Location Services are turned off. \nTo add or update this post's location, please enable Location Services in the Settings app.", @"Message of an alert explaining that location services need to be enabled.")
                          withSupportButton:NO];

                return;
            }

            if (!self.isUpdatingLocation) {
                if (self.post.geolocation) {
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedUpdateLocation forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                } else {
                    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedAddLocation forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
                }
                // Add or replace geotag
                self.isUpdatingLocation = YES;
                [self.locationManager startUpdatingLocation];
            }
            break;
        case 2:
            [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedRemoveLocation forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];

            if (self.isUpdatingLocation) {
                // Cancel update
                self.isUpdatingLocation = NO;
                [self.locationManager stopUpdatingLocation];
            }
            self.post.geolocation = nil;
            break;
    }
    [self.tableView reloadData];
}

- (void)featuredImageUploadFailed:(NSNotification *)notificationInfo {
    self.isUploadingFeaturedImage = NO;
    [self.featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.featuredImageSpinner stopAnimating];
    [self.featuredImageSpinner setHidden:YES];
    [self.featuredImageView setHidden:NO];
    [self.tableView reloadData];
}

- (void)featuredImageUploadSucceeded:(NSNotification *)notificationInfo {
    self.isUploadingFeaturedImage = NO;
    Media *media = (Media *)[notificationInfo object];
    if (media) {
        [self.featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self.featuredImageSpinner stopAnimating];
        [self.featuredImageSpinner setHidden:YES];
        [self.featuredImageLabel setHidden:YES];
        [self.featuredImageView setHidden:NO];
        if (![self.post isDeleted] && [self.post managedObjectContext]) {
            self.post.post_thumbnail = media.mediaID;
        }
        [self.featuredImageView setImage:[UIImage imageWithContentsOfFile:media.localURL]];
    }
    [self.tableView reloadData];
}

- (void)showFeaturedImageUploader:(NSNotification *)notificationInfo {
    self.isUploadingFeaturedImage = YES;
    [self.featuredImageView setHidden:YES];
    [self.featuredImageLabel setHidden:NO];
    [self.featuredImageLabel setText:NSLocalizedString(@"Uploading Image", @"Uploading a featured image in post settings")];
    [self.featuredImageSpinner setHidden:NO];
    if (!self.featuredImageSpinner.isAnimating) {
        [self.featuredImageSpinner startAnimating];
    }
    [self.tableView reloadData];
}

- (NSString *)formattedStatEventString:(NSString *)event {
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)acSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (acSheet.tag == TAG_ACTIONSHEET_PHOTO) {
        [self processPhotoTypeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else if (acSheet.tag == TAG_ACTIONSHEET_RESIZE_PHOTO) {
        [self processPhotoResizeActionSheet:acSheet thatDismissedWithButtonIndex:buttonIndex];
    } else {
        if (buttonIndex == 0) {
            [self.featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            self.post.post_thumbnail = nil;
            [self.tableView reloadData];
        }
    }
}

- (void)processPhotoTypeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    CGRect frame = self.view.bounds;
    if (IS_IPAD) {
        frame = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]].frame;
    }
    NSString *buttonTitle = [acSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Add Photo from Library", nil)]) {
        [self pickPhotoFromLibrary:frame];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Take Photo", nil)]) {
        [self pickPhotoFromCamera:frame];
    }
}

- (void)processPhotoResizeActionSheet:(UIActionSheet *)acSheet thatDismissedWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            if (acSheet.numberOfButtons == 2) {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
            } else {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeSmall]];
            }
            break;
        case 1:
            if (acSheet.numberOfButtons == 2) {
                [self showCustomSizeAlert];
            } else if (acSheet.numberOfButtons == 3) {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
            } else {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeMedium]];
            }
            break;
        case 2:
            if (acSheet.numberOfButtons == 3) {
                [self showCustomSizeAlert];
            } else if (acSheet.numberOfButtons == 4) {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
            } else {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeLarge]];
            }
            break;
        case 3:
            if (acSheet.numberOfButtons == 4) {
                [self showCustomSizeAlert];
            } else {
                [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
            }
            break;
        case 4:
            [self showCustomSizeAlert];
            break;
    }
    
    _isShowingResizeActionSheet = NO;
}


- (void)showCustomSizeAlert {
    if (self.customSizeAlert) {
        [self.customSizeAlert dismiss];
        self.customSizeAlert = nil;
    }
    
    _isShowingCustomSizeAlert = YES;
    
    // Check for previous width setting
    NSString *widthText = nil;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"] != nil) {
        widthText = [[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageWidth"];
    } else {
        widthText = [NSString stringWithFormat:@"%d", (int)_currentImage.size.width];
    }
    
    NSString *heightText = nil;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"] != nil) {
        heightText = [[NSUserDefaults standardUserDefaults] objectForKey:@"prefCustomImageHeight"];
    } else {
        heightText = [NSString stringWithFormat:@"%d", (int)_currentImage.size.height];
    }
    
    WPAlertView *alertView = [[WPAlertView alloc] initWithFrame:self.view.bounds andOverlayMode:WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode];
    alertView.overlayTitle = NSLocalizedString(@"Custom Size", @"");
    alertView.overlayDescription = @"";
    alertView.footerDescription = nil;
    alertView.firstTextFieldPlaceholder = NSLocalizedString(@"Width", @"");
    alertView.firstTextFieldValue = widthText;
    alertView.secondTextFieldPlaceholder = NSLocalizedString(@"Height", @"");
    alertView.secondTextFieldValue = heightText;
    alertView.leftButtonText = NSLocalizedString(@"Cancel", @"Cancel button");
    alertView.rightButtonText = NSLocalizedString(@"OK", @"");
    
    alertView.firstTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    alertView.secondTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    alertView.firstTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    alertView.secondTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
    alertView.firstTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertView.secondTextField.keyboardType = UIKeyboardTypeNumberPad;
    
    alertView.button1CompletionBlock = ^(WPAlertView *overlayView){
        // Cancel
        [overlayView dismiss];
        _isShowingCustomSizeAlert = NO;
        
    };
    alertView.button2CompletionBlock = ^(WPAlertView *overlayView){
        [overlayView dismiss];
        _isShowingCustomSizeAlert = NO;
        
		NSNumber *width = [NSNumber numberWithInt:[overlayView.firstTextField.text intValue]];
		NSNumber *height = [NSNumber numberWithInt:[overlayView.secondTextField.text intValue]];
		
		if([width intValue] < 10)
			width = [NSNumber numberWithInt:10];
		if([height intValue] < 10)
			height = [NSNumber numberWithInt:10];
		
		overlayView.firstTextField.text = [NSString stringWithFormat:@"%@", width];
		overlayView.secondTextField.text = [NSString stringWithFormat:@"%@", height];
		
		[[NSUserDefaults standardUserDefaults] setObject:overlayView.firstTextField.text forKey:@"prefCustomImageWidth"];
		[[NSUserDefaults standardUserDefaults] setObject:overlayView.secondTextField.text forKey:@"prefCustomImageHeight"];
		
		[self useImage:[self resizeImage:_currentImage width:[width floatValue] height:[height floatValue]]];
    };
    
    alertView.alpha = 0.0;
    [self.view addSubview:alertView];
    
    [UIView animateWithDuration:0.2 animations:^{
        alertView.alpha = 1.0;
    }];
    
    self.customSizeAlert = alertView;
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)aPickerView numberOfRowsInComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [self.statusList count];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [self.visibilityList count];
    } else if (aPickerView.tag == TAG_PICKER_FORMAT) {
        return [self.formatsList count];
    }
    return 0;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)aPickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        return [self.statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        return [self.visibilityList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_FORMAT) {
        return [self.formatsList objectAtIndex:row];
    }

    return @"";
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (aPickerView.tag == TAG_PICKER_STATUS) {
        self.apost.statusTitle = [self.statusList objectAtIndex:row];
    } else if (aPickerView.tag == TAG_PICKER_VISIBILITY) {
        NSString *visibility = [self.visibilityList objectAtIndex:row];
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
        self.post.postFormatText = [self.formatsList objectAtIndex:row];
    }
    [self.tableView reloadData];
}

#pragma mark - Pickers and keyboard animations

- (void)showPicker:(UIView *)picker {
    if (self.isShowingKeyboard) {
        [self.passwordTextField resignFirstResponder];
    }

    if (IS_IPAD) {
        UIViewController *fakeController = [[UIViewController alloc] init];
        
        if (picker.tag == TAG_PICKER_DATE) {
            fakeController.preferredContentSize = CGSizeMake(320.0f, 256.0f);

            UIButton *button = [[UIButton alloc] init];
            [button addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")] forState:UIControlStateNormal];            [button sizeToFit];
            CGPoint buttonCenter = button.center;
            buttonCenter.x = CGRectGetMidX(picker.frame);
            button.center = buttonCenter;

            [fakeController.view addSubview:button];
            CGRect pickerFrame = picker.frame;
            pickerFrame.origin.y = CGRectGetMaxY(button.frame);
            picker.frame = pickerFrame;
        } else {
            fakeController.preferredContentSize = CGSizeMake(320.0f, 216.0f);
        }
        
        [fakeController.view addSubview:picker];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:fakeController];
        
        CGRect popoverRect;
        if (picker.tag == TAG_PICKER_STATUS) {
            popoverRect = [self.view convertRect:self.statusLabel.frame fromView:[self.statusLabel superview]];
        } else if (picker.tag == TAG_PICKER_VISIBILITY) {
            popoverRect = [self.view convertRect:self.visibilityLabel.frame fromView:[self.visibilityLabel superview]];
        } else if (picker.tag == TAG_PICKER_FORMAT) {
            popoverRect = [self.view convertRect:self.postFormatLabel.frame fromView:[self.postFormatLabel superview]];
        } else {
            popoverRect = [self.view convertRect:self.publishOnDateLabel.frame fromView:[self.publishOnDateLabel superview]];
        }

        popoverRect.size.width = 100.0f;
        [self.popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        CGFloat width = self.view.frame.size.width;
        CGFloat height = 0.0;
        
        // Refactor this class to not use UIActionSheets for display. See trac #1509.
        // <rant>Shoehorning a UIPicker inside a UIActionSheet is just madness.</rant>
        // For now, hardcoding height values for the iPhone so we don't get
        // a funky gap at the bottom of the screen on the iPhone 5.
        if(self.view.frame.size.height <= 416.0f) {
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
        
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [self.actionSheet setActionSheetStyle:UIActionSheetStyleAutomatic];
        [self.actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)];
        [self.actionSheet addSubview:pickerWrapperView];
        
        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(hidePicker) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
        [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
        [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Done", @"Default main action button for closing/finishing a work flow in the app (used in Comments>Edit, Comment edits and replies, post editor body text, etc, to dismiss keyboard).")] forState:UIControlStateNormal];
        [button sizeToFit];
        CGRect frame = button.frame;
        frame.origin.x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(button.frame) - 10;
        frame.origin.y = 7;
        button.frame = frame;
        [pickerWrapperView addSubview:button];
        
        button = [[UIButton alloc] init];
        [button setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
        [button addTarget:self action:@selector(removeDate) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButton-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
        [button setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted-ios7"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
        [button setTitle:[NSString stringWithFormat:@" %@ ", NSLocalizedString(@"Publish Immediately", @"Post publishing status in the Post Editor/Settings area (compare with WP core translations).")] forState:UIControlStateNormal];
        [button sizeToFit];
        frame = button.frame;
        frame.origin.x = 10;
        frame.origin.y = 7;
        button.frame = frame;
        [pickerWrapperView addSubview:button];

        [self.actionSheet showInView:self.view];
        [self.actionSheet setBounds:CGRectMake(0.0f, 0.0f, width, height)]; // Update the bounds again now that its in the view else it won't draw correctly.
    }
}

- (void)hidePicker {
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
     self.actionSheet = nil;
}

- (void)removeDate {
    self.datePickerView.date = [NSDate date];
    self.apost.dateCreated = nil;
    [self.tableView reloadData];
    if (IS_IPAD) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self hidePicker];
    }
}

- (void)keyboardWillShow:(NSNotification *)keyboardInfo {
    self.isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)keyboardInfo {
    self.isShowingKeyboard = NO;
}

#pragma mark - CLLocationManager

- (CLLocationManager *)locationManager {
    if (_locationManager) {
        return _locationManager;
    }
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.distanceFilter = 10;
    return _locationManager;
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
		if (!self.isUpdatingLocation) {
			return;
		}
		self.isUpdatingLocation = NO;
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
        DDLogInfo(@"Added geotag (%+.6f, %+.6f)",
                  c.latitude,
                  c.longitude);
		[self.locationManager stopUpdatingLocation];
		[self.tableView reloadData];
		
		[self geocodeCoordinate:c.coordinate];

    }
    // else skip the event and process the next one.
}

#pragma mark - CLGecocoder wrapper

- (void)geocodeCoordinate:(CLLocationCoordinate2D)c {
	if (self.reverseGeocoder) {
		if (self.reverseGeocoder.geocoding)
			[self.reverseGeocoder cancelGeocode];
	}
    self.reverseGeocoder = [[CLGeocoder alloc] init];
    [self.reverseGeocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:c.latitude longitude:c.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            if (placemark.subLocality) {
                self.address = [NSString stringWithFormat:@"%@, %@, %@", placemark.subLocality, placemark.locality, placemark.country];
            } else {
                self.address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
            }
            self.addressLabel.text = self.address;
        } else {
            DDLogError(@"Reverse geocoder failed for coordinate (%.6f, %.6f): %@",
                  c.latitude,
                  c.longitude,
                  [error localizedDescription]);
            
            self.address = [NSString stringWithString:NSLocalizedString(@"Location unknown", @"Used when geo-tagging posts, if the geo-tagging failed.")];
            self.addressLabel.text = self.address;
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
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (assetURL) {
        [self getMetadataFromAssetForURL:assetURL];
    } else {
        NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
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
    BOOL showResizeActionSheet = NO;
    switch ([resizePreference intValue]) {
        case 0:
        {
            // Dispatch async to detal with a rare bug presenting the actionsheet after a memory warning when the
            // view has been recreated.
            showResizeActionSheet = YES;
            break;
        }
        case 1:
        {
            [self useImage:[self resizeImage:_currentImage toSize:MediaResizeSmall]];
            break;
        }
        case 2:
        {
            [self useImage:[self resizeImage:_currentImage toSize:MediaResizeMedium]];
            break;
        }
        case 3:
        {
            [self useImage:[self resizeImage:_currentImage toSize:MediaResizeLarge]];
            break;
        }
        case 4:
        {
            //[self useImage:currentImage];
            [self useImage:[self resizeImage:_currentImage toSize:MediaResizeOriginal]];
            break;
        }
        default:
        {
            showResizeActionSheet = YES;
            break;
        }
    }

    BOOL isPopoverDisplayed = NO;
    if (IS_IPAD) {
        if (thePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            isPopoverDisplayed = NO;
        } else {
            isPopoverDisplayed = YES;
        }
    }
    
    if (isPopoverDisplayed) {
        [self.popover dismissPopoverAnimated:YES];
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
					   
					   DDLogInfo(@"getJPEGFromAssetForURL: default asset representation for %@: uti: %@ size: %lld url: %@ orientation: %d scale: %f metadata: %@",
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
						   DDLogError(@"error from getBytes: %@", err);
						   
						   return;
					   }
					   NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf length:[rep size]
														  freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
					   
					   CGImageSourceRef  source ;
					   source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, nil);
					   
                       NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,nil));
                       
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
					  DDLogError(@"can't get asset %@: %@", url, err);
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
		case MediaResizeSmall:
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
		case MediaResizeMedium:
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
		case MediaResizeLarge:
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
		case MediaResizeOriginal:
			resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
														  bounds:originalSize
											interpolationQuality:kCGInterpolationHigh];
			break;
	}
    
	return resizedImage;
}

/* Used in Custom Dimensions Resize */
- (UIImage *)resizeImage:(UIImage *)original width:(CGFloat)width height:(CGFloat)height {
	UIImage *resizedImage = original;
	if(_currentImage.size.width > width || _currentImage.size.height > height) {
		// Resize the image using the selected dimensions
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
													  bounds:CGSizeMake(width, height)
										interpolationQuality:kCGInterpolationHigh];
	} else {
		//use the original dimension
		resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
													  bounds:CGSizeMake(_currentImage.size.width, _currentImage.size.height)
										interpolationQuality:kCGInterpolationHigh];
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
		CGImageSourceRef  source = nil;
        CGImageDestinationRef destination = nil;
		BOOL success = NO;
        //this will be the data CGImageDestinationRef will write into
        NSMutableData *dest_data = [NSMutableData data];
        
		source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,nil);
            
            if(destination) {
                //add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) _currentImageMetadata);
                
                //tell the destination to write the image data and metadata into our data object.
                //It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
            } else {
                DDLogError(@"***Could not create image destination ***");
            }
        } else {
            DDLogError(@"***Could not create image source ***");
        }
		
		if(!success) {
			DDLogError(@"***Could not create data from image destination ***");
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
    
	if ([self interpretOrientation] == MediaOrientationLandscape) {
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
            DDLogWarn(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
        [imageMedia save];
    } failure:^(NSError *error) {
        [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Upload failed", @"")];
    }];
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (MediaOrientation)interpretOrientation {
	MediaOrientation result = MediaOrientationPortrait;
	switch ([[UIDevice currentDevice] orientation]) {
		case UIDeviceOrientationPortrait:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationLandscapeLeft:
			result = MediaOrientationLandscape;
			break;
		case UIDeviceOrientationLandscapeRight:
			result = MediaOrientationLandscape;
			break;
		case UIDeviceOrientationFaceUp:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationFaceDown:
			result = MediaOrientationPortrait;
			break;
		case UIDeviceOrientationUnknown:
			result = MediaOrientationPortrait;
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
		
		if(_currentImage.size.width > largeSize.width  && _currentImage.size.height > largeSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, resizeLargeStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > mediumSize.width  && _currentImage.size.height > mediumSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, resizeMediumStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else if(_currentImage.size.width > smallSize.width  && _currentImage.size.height > smallSize.height) {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles:resizeSmallStr, originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
			
		} else {
			resizeActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Image Size", @"")
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  destructiveButtonTitle:nil
												   otherButtonTitles: originalSizeStr, NSLocalizedString(@"Custom", @""), nil];
		}
		
        resizeActionSheet.tag = TAG_ACTIONSHEET_RESIZE_PHOTO;
        
        UITableViewCell *featuredImageCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
        if (featuredImageCell != nil) {
            [resizeActionSheet showFromRect:featuredImageCell.frame inView:self.view animated:YES];
        } else {
            [resizeActionSheet showInView:self.view];
        }
	}
}


#pragma mark - Private Methods

- (NSString *)titleForVisibility {
    if (self.apost.password) {
        return NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP.");
    } else if ([self.apost.status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.");
    } else {
        return NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP.");
    }
}

- (void)showPhotoPickerForRect:(CGRect)frame {
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

- (void)pickPhotoFromLibrary:(CGRect)frame {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    picker.navigationBar.barStyle = UIBarStyleBlack;
    
    if (IS_IPAD) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        self.popover.delegate = self;
        [self.popover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [[CPopoverManager instance] setCurrentPopoverController:self.popover];
    } else {
        [self.navigationController presentViewController:picker animated:YES completion:nil];
    }
}

- (void)pickPhotoFromCamera:(CGRect)frame {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    // On iOS7 Beta 6 the image picker seems to override our preferred setting so we force the status bar color back.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)dismissTagsKeyboardIfAppropriate:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView:self.tableView];
    if (!CGRectContainsPoint(self.tagsTextField.frame, touchPoint) && [self.tagsTextField isFirstResponder]) {
        [self.tagsTextField resignFirstResponder];
    }
}

#pragma mark - Categories Related

- (void)showCategoriesSelectionView:(CGRect)cellFrame {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedShowCategories forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    [self populateSelectionsControllerWithCategories:cellFrame];
}

- (void)populateSelectionsControllerWithCategories:(CGRect)cellFrame {
    DDLogMethod();
    if (_segmentedTableViewController == nil) {
        _segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] init];
    }
    
    NSArray *cats = [self.post.blog sortedCategories];
    NSArray *selObject = [self.post.categories allObjects];
    
    [_segmentedTableViewController populateDataSource:cats    //datasource
                                       havingContext:kSelectionsCategoriesContext
                                     selectedObjects:selObject
                                       selectionType:kCheckbox
                                         andDelegate:self];
    
    _segmentedTableViewController.title = NSLocalizedString(@"Categories", @"");
    
    UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAddNewCategoryView:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *createCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:createCategoryBarButtonItem forNavigationItem:_segmentedTableViewController.navigationItem];
        
    if (!_isNewCategory) {
        [self.navigationController pushViewController:_segmentedTableViewController animated:YES];
    }
    
    _isNewCategory = NO;
}

- (IBAction)showAddNewCategoryView:(id)sender {
    DDLogMethod();
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithBlog:self.post.blog];
	if (IS_IPAD) {
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
        [self.post.categories removeAllObjects];
        [self.post.categories addObjectsFromArray:selectedObjects];
        [self.tableView reloadData];
    }
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification {
    DDLogMethod();
    if ([_segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        _isNewCategory = YES;
        [self populateSelectionsControllerWithCategories:CGRectZero];
    }
}


@end

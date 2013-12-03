#import "PostSettingsViewController.h"
#import "WPSelectionTableViewController.h"
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
#import "MediaBrowserViewController.h"

#define kPasswordFooterSectionHeight        68.0f
#define kResizePhotoSettingSectionHeight    60.0f
#define TAG_PICKER_STATUS                   0
#define TAG_PICKER_VISIBILITY               1
#define TAG_PICKER_DATE                     2
#define TAG_PICKER_FORMAT                   3
#define TAG_ACTIONSHEET_PHOTO               10
#define TAG_ACTIONSHEET_RESIZE_PHOTO        20
#define kOFFSET_FOR_KEYBOARD                150.0

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
@property (nonatomic, strong) IBOutlet UITableViewCell *visibilityTableViewCell;
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
@property (nonatomic, strong) UITableViewActivityCell *addGeotagTableViewCell;
@property (nonatomic, strong) UITableViewCell *removeGeotagTableViewCell;
@property (nonatomic, strong) PostAnnotation *annotation;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) BOOL isUpdatingLocation, isUploadingFeaturedImage;

// Featured image
@property (nonatomic, strong) IBOutlet UILabel *visibilityTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *featuredImageLabel;
@property (nonatomic, strong) IBOutlet UIImageView *featuredImageView;
@property (nonatomic, strong) IBOutlet UITableViewCell *featuredImageTableViewCell;
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
    self.title = NSLocalizedString(@"Properties", nil);
    
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featuredImageSelected:) name:FeaturedImageSelected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
    
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
                    // TODO Replace with media library support
                    //[self showFeaturedImageUploader:nil];
                }
            }
        }
        
        if (!self.isUploadingFeaturedImage && (self.blogSupportsFeaturedImage && self.post.post_thumbnail != nil)) {
            // Download the current featured image
            [self.featuredImageView setHidden:YES];
            [self.featuredImageLabel setText:NSLocalizedString(@"Loading Featured Image", @"Loading featured image in post settings")];
            [self.featuredImageLabel setHidden:NO];
            [self.featuredImageSpinner setHidden:NO];
            if (!self.featuredImageSpinner.isAnimating)
                [self.featuredImageSpinner startAnimating];
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
	[self.postDetailViewController refreshButtons];
    [self.tableView reloadData];
}

#pragma mark - TextField Delegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        self.apost.password = textField.text;
    } else if (textField == self.tagsTextField) {
        self.post.tags = self.tagsTextField.text;
        [self.postDetailViewController refreshTags];
    }
    [self.postDetailViewController refreshButtons];
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
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CategoriesCellIdentifier];
                    }
                    cell.textLabel.text = NSLocalizedString(@"Categories:", @"Label for the categories field. Should be the same as WP core.");
                    cell.detailTextLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
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
                    cell.textLabel.text = NSLocalizedString(@"Tags:", @"Label for the tags field. Should be the same as WP core.");
                    cell.textField.text = self.post.tags;
                    cell.textField.placeholder = NSLocalizedString(@"Separate tags with commas", @"Placeholder text for the tags field. Should be the same as WP core.");
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
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:StatusCellIdentifier];
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
				
                if (!IS_IOS7) {
                    [self.visibilityTitleLabel setHighlightedTextColor:[UIColor whiteColor]];
                    [self.visibilityLabel setHighlightedTextColor:[UIColor whiteColor]];
                }
				return self.visibilityTableViewCell;
				break;
			case 2:
			{
                static NSString *PublishedOnCellIdentifier = @"PublishedOnCell";
                UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PublishedOnCellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:PublishedOnCellIdentifier];
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
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:PostFormatCellIdentifier];
            }

            cell.textLabel.text = NSLocalizedString(@"Post Format", @"The post formats available for the post. Should be the same as in core WP.");
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
                UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:@"CustomCell"];

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
                    activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                [WPStyleGuide configureTableViewActionCell:activityCell];
                if (!IS_IOS7) {
                    [activityCell.textLabel setHighlightedTextColor:[UIColor whiteColor]];
                    [activityCell.detailTextLabel setHighlightedTextColor:[UIColor whiteColor]];
                }
                [activityCell.textLabel setText:NSLocalizedString(@"Set Featured Image", @"")];
                return activityCell;
            } else {
                switch (indexPath.row) {
                    case 0:
                        if (self.featuredImageTableViewCell == nil) {
                            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                            for(id currentObject in topLevelObjects) {
                                if([currentObject isKindOfClass:[UITableViewActivityCell class]]) {
                                    self.featuredImageTableViewCell = (UITableViewActivityCell *)currentObject;
                                    break;
                                }
                            }
                        }
                        return self.featuredImageTableViewCell;
                        break;
                    case 1: {
                        UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
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
                        if (!IS_IOS7) {
                            [activityCell.textLabel setHighlightedTextColor:[UIColor whiteColor]];
                            [activityCell.detailTextLabel setHighlightedTextColor:[UIColor whiteColor]];
                        }
                        [WPStyleGuide configureTableViewActionCell:activityCell];
                        return activityCell;
                        break;
                    }
                        
                }
            }
        } else {
            return [self getGeolocationCellWithIndexPath:indexPath];
        }
        break;
    case 4:
        return [self getGeolocationCellWithIndexPath:indexPath];
        break;
	}
    
    return nil;
}

- (UITableViewCell*)getGeolocationCellWithIndexPath:(NSIndexPath*)indexPath {
    switch (indexPath.row) {
        case 0: // Add/update location
        {
            // If location services are disabled at the app level [CLLocationManager locationServicesEnabled] will be true, but the location will be nil.
            if(!self.post.blog.geolocationEnabled) {
                UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"GeolocationDisabledCell"];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GeolocationDisabledCell"];
                    cell.textLabel.text = NSLocalizedString(@"Enable Geotagging to Edit", @"Prompt the user to enable geolocation tagging on their blog.");
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    [WPStyleGuide configureTableViewActionCell:cell];
                }
                return cell;
                
            } else if(![CLLocationManager locationServicesEnabled] || [self.locationManager location] == nil) {
                UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"locationServicesCell"];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"locationServicesCell"];
                    cell.textLabel.text = NSLocalizedString(@"Please Enable Location Services", @"Prompt the user to enable location services on their device.");
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    [WPStyleGuide configureTableViewActionCell:cell];
                }
                return cell;
                
            } else {
            
                if (self.addGeotagTableViewCell == nil) {
                    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
                    for(id currentObject in topLevelObjects) {
                        if([currentObject isKindOfClass:[UITableViewActivityCell class]]) {
                            self.addGeotagTableViewCell = (UITableViewActivityCell *)currentObject;
                            break;
                        }
                    }
                }
                if (self.isUpdatingLocation) {
                    self.addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");
                    [self.addGeotagTableViewCell.spinner startAnimating];
                } else {
                    [self.addGeotagTableViewCell.spinner stopAnimating];
                    if (self.post.geolocation) {
                        self.addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Update Location", @"Gelocation feature to update physical location.");
                    } else {
                        self.addGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Add Location", @"Geolocation feature to add location.");
                    }
                }
                [WPStyleGuide configureTableViewActionCell:self.addGeotagTableViewCell];
                return self.addGeotagTableViewCell;
            }
            break;
        }
        case 1:
        {
            DDLogVerbose(@"Reloading map");
            if (self.mapGeotagTableViewCell == nil) {
                self.mapGeotagTableViewCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 188)];
            }
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
            //				coordinateLabel.text = [NSString stringWithFormat:@"%.6f, %.6f",
            //										self.post.geolocation.latitude,
            //										self.post.geolocation.longitude];
            self.coordinateLabel.font = [WPStyleGuide regularTextFont];
            self.coordinateLabel.textColor = [WPStyleGuide allTAllShadeGrey];
            
            [self.mapGeotagTableViewCell addSubview:self.mapView];
            [self.mapGeotagTableViewCell addSubview:self.addressLabel];
            [self.mapGeotagTableViewCell addSubview:self.coordinateLabel];
            
            return self.mapGeotagTableViewCell;
            break;
        }
        case 2:
        {
            if (self.removeGeotagTableViewCell == nil) {
                self.removeGeotagTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RemoveGeotag"];
            }
            self.removeGeotagTableViewCell.textLabel.text = NSLocalizedString(@"Remove Location", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
            self.removeGeotagTableViewCell.textLabel.textAlignment = NSTextAlignmentCenter;
            [WPStyleGuide configureTableViewActionCell:self.removeGeotagTableViewCell];
            return self.removeGeotagTableViewCell;
            break;
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
                            MediaBrowserViewController *vc = [[MediaBrowserViewController alloc] initWithPost:self.apost settingFeaturedImage:YES];
                            [self.navigationController pushViewController:vc animated:YES];
                            [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedSetFeaturedImage forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
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
            if(![CLLocationManager locationServicesEnabled] || [self.locationManager location] == nil) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Unavailable", @"Title of an alert view stating that the user's location is unavailable.")
                                                                    message:NSLocalizedString(@"Location Services are turned off. \nTo add or update this post's location, please enable Location Services in the Settings app.", @"Message of an alert explaining that location services need to be enabled.")
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                [alertView show];
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
            self.postDetailViewController.hasLocation.enabled = NO;
            [self.postDetailViewController refreshButtons];
            break;
    }
    [self.tableView reloadData];
}

- (void)featuredImageSelected:(NSNotification *)notificationInfo {
    Media *media = (Media *)[notificationInfo object];
    if (media) {
        BOOL localFileExists = media.localURL && [[NSFileManager defaultManager] fileExistsAtPath:media.localURL isDirectory:0];
        if (localFileExists) {
            self.featuredImageView.image = [UIImage imageWithContentsOfFile:media.localURL];
        } else {
            [self loadFeaturedImage:[NSURL URLWithString:media.remoteURL]];
        }
        
        if (![self.post isDeleted] && [self.post managedObjectContext]) {
            self.post.post_thumbnail = media.mediaID;
        }
    }
    [self.postDetailViewController refreshButtons];
    [self.tableView reloadData];
}

- (NSString *)formattedStatEventString:(NSString *)event
{
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

#pragma mark -
- (void)actionSheet:(UIActionSheet *)acSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.featuredImageTableViewCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        self.post.post_thumbnail = nil;
        [self.postDetailViewController refreshButtons];
        [self.tableView reloadData];

    }
}

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
	[self.postDetailViewController refreshButtons];
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
        CGFloat width = self.postDetailViewController.view.frame.size.width;
        CGFloat height = 0.0;
        
        // Refactor this class to not use UIActionSheets for display. See trac #1509.
        // <rant>Shoehorning a UIPicker inside a UIActionSheet is just madness.</rant>
        // For now, hardcoding height values for the iPhone so we don't get
        // a funky gap at the bottom of the screen on the iPhone 5.
        if(self.postDetailViewController.view.frame.size.height <= 416.0f) {
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
		self.postDetailViewController.hasLocation.enabled = YES;
        DDLogInfo(@"Added geotag (%+.6f, %+.6f)",
                  c.latitude,
                  c.longitude);
		[self.locationManager stopUpdatingLocation];
        [self.postDetailViewController refreshButtons];
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

    if (IS_IOS7) {
        UIImage *image = [UIImage imageNamed:@"icon-posts-add"];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showAddNewCategoryView:) forControlEvents:UIControlEventTouchUpInside];
        createCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    } else {
        createCategoryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"]
                                                                       style:[WPStyleGuide barButtonStyleForBordered]
                                                                      target:self
                                                                      action:@selector(showAddNewCategoryView:)];
    }


    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:createCategoryBarButtonItem forNavigationItem:_segmentedTableViewController.navigationItem];
    
    
    if (!_isNewCategory) {
        [self.navigationController pushViewController:_segmentedTableViewController animated:YES];
    }
    
    _isNewCategory = NO;
}

- (IBAction)showAddNewCategoryView:(id)sender {
    WPFLogMethod();
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
    addCategoryViewController.blog = self.post.blog;
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
    WPFLogMethod();
    if ([_segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        _isNewCategory = YES;
        [self populateSelectionsControllerWithCategories:CGRectZero];
    }
}


@end

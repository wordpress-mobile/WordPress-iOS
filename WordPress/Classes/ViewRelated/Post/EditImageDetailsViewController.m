#import "EditImageDetailsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <WordPressEditor/WPImageMeta.h>
#import <WordPressShared/UIImage+Util.h>
#import <WordPressShared/WPTextFieldTableViewCell.h>
#import "AbstractPost.h"
#import "SettingsSelectionViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPGUIConstants.h"
#import "WordPress-Swift.h"

static NSString *const TextFieldCell = @"TextFieldCell";
static NSString *const FeaturedCellIdentifier = @"FeaturedCellIdentifier";
static NSString *const CellIdentifier = @"CellIdentifier";
static NSString *const ThumbCellIdentifier = @"ThumbCellIdentifier";

static CGFloat CellHeight = 44.0f;

typedef NS_ENUM(NSUInteger, ImageDetailsSection) {
    ImageDetailsSectionThumb,
    ImageDetailsSectionDetails,
    ImageDetailsSectionDisplay,
    ImageDetailsSectionFeatured
};

typedef NS_ENUM(NSUInteger, ImageDetailsRow) {
    ImageDetailsRowThumb,
    ImageDetailsRowFeatured,
    ImageDetailsRowTitle,
    ImageDetailsRowCaption,
    ImageDetailsRowAlt,
    ImageDetailsRowAlign,
    ImageDetailsRowLink,
    ImageDetailsRowSize
};

@interface EditImageDetailsViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSArray *alignTitles;
@property (nonatomic, strong) NSArray *alignValues;
@property (nonatomic, strong) NSArray *sizeTitles;
@property (nonatomic, strong) NSArray *sizeValues;

@property (nonatomic, strong) SettingTableViewCell *imageTitleCell;
@property (nonatomic, strong) SettingTableViewCell *imageCaptionCell;
@property (nonatomic, strong) SettingTableViewCell *imageAltTextCell;
@property (nonatomic, strong) SettingTableViewCell *imageLinkCell;

@property (nonatomic) BOOL setMediaAsFeaturedImage;
@end

@implementation EditImageDetailsViewController

+ (instancetype)controllerForDetails:(WPImageMeta *)details
                               media:(Media *)media
                             forPost:(AbstractPost *)post
{
    EditImageDetailsViewController *controller = [[EditImageDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.imageDetails = details;
    controller.post = post;
    controller.media = media;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Edit Image", @"Title of the edit image details screen.");

    [self.tableView registerClass:[WPTextFieldTableViewCell class] forCellReuseIdentifier:TextFieldCell];
    [self.tableView registerClass:[SwitchTableViewCell class] forCellReuseIdentifier:FeaturedCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ThumbCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
    self.tableView.accessibilityIdentifier = @"ImageDetailsTable";
    UIGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapInView:)];
    tgr.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tgr];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                              target:self
                                                              action:@selector(handleCancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                              target:self
                                                              action:@selector(handleDoneButtonTapped:)];
    self.navigationItem.rightBarButtonItem = doneButton;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    self.imageTitleCell.textValue = self.imageDetails.title;
    self.imageCaptionCell.textValue = self.imageDetails.caption;
    self.imageAltTextCell.textValue = self.imageDetails.alt;
    self.imageLinkCell.textValue = self.imageDetails.linkURL;
    self.setMediaAsFeaturedImage = (self.post.featuredImage == self.media);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


#pragma mark - Getters

- (NSArray *)alignTitles
{
    if (_alignTitles) {
        return _alignTitles;
    }
    _alignTitles = @[
                     NSLocalizedString(@"Left", @"Left alignment for an image. Should be the same as in core WP."),
                     NSLocalizedString(@"Center", @"Center alignment for an image. Should be the same as in core WP."),
                     NSLocalizedString(@"Right", @"Right alignment for an image. Should be the same as in core WP."),
                     NSLocalizedString(@"None", @"No alignment for an image (default). Should be the same as in core WP.")
                     ];
    return _alignTitles;
}

- (NSArray *)alignValues
{
    if (_alignValues) {
        return _alignValues;
    }
    _alignValues = @[
                     @"left",
                     @"center",
                     @"right",
                     @"none"
                     ];
    return _alignValues;
}

- (NSArray *)sizeTitles
{
    if (_sizeTitles) {
        return _sizeTitles;
    }

    NSString *thumbnail = NSLocalizedString(@"Thumbnail", @"Thumbnail image size. Should be the same as in core WP.");
    NSString *medium = NSLocalizedString(@"Medium", @"Medium image size. Should be the same as in core WP.");
    NSString *large = NSLocalizedString(@"Large", @"Large image size. Should be the same as in core WP.");
    NSString *full = NSLocalizedString(@"Full Size", @"Full size image. (default). Should be the same as in core WP.");

    NSDictionary *sizes = [self.post.blog getImageResizeDimensions];
    CGSize imageSize = [self imageSize];
    CGSize size = CGSizeZero;
    CGSize maxSize = [[sizes valueForKey:@"smallSize"] CGSizeValue];
    if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
        size = [self sizeForSize:imageSize withMaxSize:maxSize];
        thumbnail = [NSString stringWithFormat:@"%@ - %d x %d", thumbnail, (NSInteger)size.width, (NSInteger)size.height];
    }
    maxSize = [[sizes valueForKey:@"mediumSize"] CGSizeValue];
    if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
        size = [self sizeForSize:imageSize withMaxSize:maxSize];
        medium = [NSString stringWithFormat:@"%@ - %d x %d", medium, (NSInteger)size.width, (NSInteger)size.height];
    }
    maxSize = [[sizes valueForKey:@"largeSize"] CGSizeValue];
    if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
        size = [self sizeForSize:imageSize withMaxSize:maxSize];
        large = [NSString stringWithFormat:@"%@ - %d x %d", large, (NSInteger)size.width, (NSInteger)size.height];
    }

    _sizeTitles = @[thumbnail, medium, large, full];
    return _sizeTitles;
}

- (CGSize)sizeForSize:(CGSize)size withMaxSize:(CGSize)maxSize
{
    CGSize newSize = size;
    CGFloat ratio = size.width / size.height;

    if (size.width > maxSize.width) {
        newSize.width = maxSize.width;
        newSize.height = newSize.width / ratio;
    }

    if (size.height > maxSize.height) {
        newSize.height = maxSize.height;
        newSize.width = newSize.height * ratio;
    }

    return newSize;
}

- (NSArray *)sizeValues
{
    if (_sizeValues) {
        return _sizeValues;
    }
    _sizeValues = @[
                    @"thumbnail",
                    @"medium",
                    @"large",
                    @"full"
                    ];
    return _sizeValues;
}

- (CGSize)imageSize
{
    return CGSizeMake([self.imageDetails.naturalWidth floatValue], [self.imageDetails.naturalHeight floatValue]);
}

#pragma mark - Configuration

- (void)configureSections
{
    self.sections = [NSMutableArray array];
    [self.sections addObject:@(ImageDetailsSectionThumb)];
    [self.sections addObject:@(ImageDetailsSectionDetails)];
    [self.sections addObject:@(ImageDetailsSectionDisplay)];

    if (self.media && self.media.assetType == WPMediaTypeImage) {
        [self.sections addObject:@(ImageDetailsSectionFeatured)];
    }
}


#pragma mark - Actions

- (void)handleCancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleDoneButtonTapped:(id)sender
{
    self.imageDetails.title = self.imageTitleCell.textValue;
    self.imageDetails.caption = self.imageCaptionCell.textValue;
    self.imageDetails.alt = self.imageAltTextCell.textValue;
    self.imageDetails.linkURL = self.imageLinkCell.textValue;

    self.post.featuredImage = (self.setMediaAsFeaturedImage) ? self.media : nil;

    [self.delegate editImageDetailsViewController:self didFinishEditingImageDetails:self.imageDetails];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTapInView:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.sections) {
        [self configureSections];
    }
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];

    switch (sec) {
        case ImageDetailsSectionThumb:
            return 1;
        case ImageDetailsSectionFeatured:
            return 1;
        case ImageDetailsSectionDetails:
            return 3;
        case ImageDetailsSectionDisplay:
            return 3;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == ImageDetailsSectionDetails) {
        return NSLocalizedString(@"Details", @"The title of the option group for editing an image's title, caption, etc. on the image details screen.");

    } else if (sec == ImageDetailsSectionDisplay) {
        return NSLocalizedString(@"Web Display Settings", @"The title of the option group for editing an image's size, alignment, etc. on the image details screen.");
    } else if (sec == ImageDetailsSectionFeatured) {
        return NSLocalizedString(@"Featured Image", @"The title of the option group for setting an image as a post's featured image on the image details screen.");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionHeader:view];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];

    UITableViewCell *cell;

    switch (sec) {
        case ImageDetailsSectionThumb:
            cell = [self thumbCellForIndexPath:indexPath];
            break;
        case ImageDetailsSectionFeatured:
            cell = [self featuredCellForIndexPath:indexPath];
            break;
        case ImageDetailsSectionDetails:
            cell = [self detailCellForIndexPath:indexPath];
            break;
        case ImageDetailsSectionDisplay:
            cell = [self displayCellForIndexPath:indexPath];
            break;
        default: break;
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.tag == ImageDetailsSectionFeatured) {
        return NO;
    }

    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    switch (cell.tag) {
        case ImageDetailsRowTitle:
            [self showEditImageTitleController];
            break;
        case ImageDetailsRowCaption:
            [self showEditImageCaptionController];
            break;
        case ImageDetailsRowAlt:
            [self showEditImageAltController];
            break;
        case ImageDetailsRowLink:
            [self showEditImageLinkController];
            break;
        case ImageDetailsRowAlign:
            [self showAlignmentSelector];
            break;
        case ImageDetailsRowSize:
            [self showSizeSelector];
            break;
        case ImageDetailsRowFeatured: break;
        default: break;
    }
}

#pragma mark - Cells

- (WPTextFieldTableViewCell *)getTextFieldCell
{
    WPTextFieldTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCell];
    if (!cell) {
        cell = [[WPTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextFieldCell];
    }

    cell.textField.returnKeyType = UIReturnKeyDone;
    cell.textField.delegate = self;
    [WPStyleGuide configureTableViewTextCell:cell];
    cell.textField.textAlignment = NSTextAlignmentRight;
    cell.textField.secureTextEntry = NO;
    cell.textField.clearButtonMode = UITextFieldViewModeNever;
    cell.tag = 0;

    return cell;
}

- (UITableViewCell *)thumbCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ThumbCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ThumbCellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    [WPStyleGuide configureTableViewCell:cell];

    NSURL *url = [NSURL URLWithString:self.imageDetails.src];

    __weak __typeof(self) weakSelf = self;
    [cell.imageView setImageWithURL:url
                   placeholderImage:[UIImage imageWithColor:[UIColor whiteColor] havingSize:CGSizeMake(44.0, 44.0)]
                            success:^(UIImage *image) {
                                weakSelf.image = image;
                            } failure:nil];
    cell.imageView.clipsToBounds = YES;
    cell.imageView.layer.borderWidth = 3;
    cell.imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.textLabel.text = [url lastPathComponent];

    return cell;
}

- (SettingTableViewCell *)imageTitleCell
{
    if (_imageTitleCell) {
        return _imageTitleCell;
    }
    _imageTitleCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Title", @"Label for the title field of an image.")
                                                        editable:YES
                                                 reuseIdentifier:nil];
    _imageTitleCell.tag = ImageDetailsRowTitle;
    return _imageTitleCell;
}

- (SettingTableViewCell *)imageCaptionCell
{
    if (_imageCaptionCell) {
        return _imageCaptionCell;
    }
    _imageCaptionCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Caption", @"Label for the caption field")
                                                         editable:YES
                                                  reuseIdentifier:nil];
    _imageCaptionCell.tag = ImageDetailsRowCaption;
    return _imageCaptionCell;
}

- (SettingTableViewCell *)imageAltTextCell
{
    if (_imageAltTextCell) {
        return _imageAltTextCell;
    }
    _imageAltTextCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Alt Text", @"Label for the image's alt attribute.")
                                                           editable:YES
                                                    reuseIdentifier:nil];
    _imageAltTextCell.tag = ImageDetailsRowAlt;
    return _imageAltTextCell;
}

- (SettingTableViewCell *)imageLinkCell
{
    if (_imageLinkCell) {
        return _imageLinkCell;
    }
    _imageLinkCell = [[SettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Link To", @"Image link option title")
                                                       editable:YES
                                                reuseIdentifier:nil];
    _imageLinkCell.tag = ImageDetailsRowLink;
    return _imageLinkCell;
}

- (UITableViewCell *)featuredCellForIndexPath:(NSIndexPath *)indexPath
{
    SwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:FeaturedCellIdentifier forIndexPath:indexPath];

    [WPStyleGuide configureTableViewCell:cell];

    cell.on = self.setMediaAsFeaturedImage;
    cell.name = NSLocalizedString(@"Set as Featured Image", @"Switch title in editor image settings, to set the image as a post's featured image.");

    __weak __typeof__(self) weakSelf = self;
    cell.onChange = ^(BOOL isOn) {
        weakSelf.setMediaAsFeaturedImage = isOn;
    };

    cell.tag = ImageDetailsRowFeatured;
    
    return cell;
}

- (UITableViewCell *)detailCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTextFieldTableViewCell *cell = [self getTextFieldCell];

    if (indexPath.row == 0) {
        return self.imageTitleCell;
    } else if (indexPath.row == 1) {
        return self.imageCaptionCell;

    } else if (indexPath.row == 2) {
        return self.imageAltTextCell;
    }

    return cell;
}

- (UITableViewCell *)displayCellForIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.row == 0) {
        cell.tag = ImageDetailsRowAlign;
        cell.textLabel.text = NSLocalizedString(@"Alignment", @"Image alignment option title.");
        cell.detailTextLabel.text = [self titleForAlignment:self.imageDetails.align];
        [WPStyleGuide configureTableViewCell:cell];
    } else if (indexPath.row == 1) {
        return self.imageLinkCell;
    } else if (indexPath.row == 2) {
        cell.tag = ImageDetailsRowSize;
        cell.textLabel.text = NSLocalizedString(@"Size", @"Image size option title");
        cell.detailTextLabel.text = [self titleForSize:self.imageDetails.size];
        [WPStyleGuide configureTableViewCell:cell];
    }

    return cell;
}

- (NSString *)titleForAlignment:(NSString *)align
{
    if ([self.alignValues containsObject:align]) {
        return [self.alignTitles objectAtIndex:[self.alignValues indexOfObject:align]];
    }

    return [self.alignTitles lastObject];
}

- (NSString *)titleForSize:(NSString *)size
{
    if ([self.sizeValues containsObject:size]) {
        return [self.sizeTitles objectAtIndex:[self.sizeValues indexOfObject:size]];
    }

    return [self.sizeTitles lastObject];
}


#pragma mark - Setting Selection Methods

- (void)showEditImageTitleController
{
    SettingsTextViewController *settingsTextViewController = [[SettingsTextViewController alloc] initWithText:self.imageTitleCell.textValue
                                                                                                  placeholder:NSLocalizedString(@"Add a title", @"Hint for image title. Should be the same as WP core.")
                                                                                                         hint:NSLocalizedString(@"Image title", @"Hint for image title on image settings.")];
    settingsTextViewController.title = NSLocalizedString(@"Image Title", @"Title for screen that show site title editor");
    settingsTextViewController.onValueChanged = ^(NSString *value) {
        self.imageTitleCell.detailTextLabel.text = value;
    };
    [self.navigationController pushViewController:settingsTextViewController animated:YES];
}

- (void)showEditImageCaptionController
{
    SettingsTextViewController *settingsTextViewController = [[SettingsTextViewController alloc] initWithText:self.imageCaptionCell.textValue
                                                                                                  placeholder:NSLocalizedString(@"Add a caption", @"Placeholder text for the tags field. Should be the same as WP core.")
                                                                                                         hint:NSLocalizedString(@"Image Caption", @"Hint for image caption on image settings.")];
    settingsTextViewController.title = NSLocalizedString(@"Image Caption", @"Title for screen that show image caption editor.");
    settingsTextViewController.onValueChanged = ^(NSString *value) {
        self.imageCaptionCell.detailTextLabel.text = value;
    };
    [self.navigationController pushViewController:settingsTextViewController animated:YES];
}

- (void)showEditImageAltController
{
    SettingsTextViewController *settingsTextViewController = [[SettingsTextViewController alloc] initWithText:self.imageAltTextCell.textValue
                                                                                                  placeholder:NSLocalizedString(@"Add alt text", @"Placeholder text for the tags field. Should be the same as WP core.")
                                                                                                         hint:NSLocalizedString(@"Image alt text", @"Placeholder text for the tags field. Should be the same as WP core.")];
    settingsTextViewController.title = NSLocalizedString(@"Alt Text", @"Title for screen that show image alt editor.");
    settingsTextViewController.onValueChanged = ^(NSString *value) {
        self.imageAltTextCell.detailTextLabel.text = value;
    };
    [self.navigationController pushViewController:settingsTextViewController animated:YES];
}

- (void)showEditImageLinkController
{
    SettingsTextViewController *settingsTextViewController = [[SettingsTextViewController alloc] initWithText:self.imageLinkCell.textValue
                                                                                                  placeholder:NSLocalizedString(@"http://www.example.com/", @"Placeholder text for the link field.")
                                                                                                         hint:NSLocalizedString(@"URL for image to link to", @"Hint text for link field on the image settings.")];
    settingsTextViewController.title = NSLocalizedString(@"Link To", @"Title for screen that show image link editor.");
    settingsTextViewController.onValueChanged = ^(NSString *value) {
        self.imageLinkCell.detailTextLabel.text = value;
    };
    [self.navigationController pushViewController:settingsTextViewController animated:YES];
}

- (void)showAlignmentSelector
{
    NSArray *titles = self.alignTitles;
    NSArray *values = self.alignValues;

    NSString *currentValue = [values lastObject];
    if ([values containsObject:self.imageDetails.align]) {
        currentValue = self.imageDetails.align;
    }

    NSDictionary *dict = @{
                           @"DefaultValue"   : [titles lastObject],
                           @"Title"          : NSLocalizedString(@"Alignment", @"Title of the screen for choosing an image's alignment."),
                           @"Titles"         : titles,
                           @"Values"         : values,
                           @"CurrentValue"   : currentValue
                           };

    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:dict];
    __weak SettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *status) {
        // do interesting work here... like updating the value of image meta.
        self.imageDetails.align = status;

        [weakVc dismiss];
        [self.tableView reloadData];
    };

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showSizeSelector
{
    NSArray *titles = self.sizeTitles;
    NSArray *values = self.sizeValues;

    NSString *currentValue = [values lastObject];
    if ([values containsObject:self.imageDetails.size]) {
        currentValue = self.imageDetails.size;
    }

    NSDictionary *dict = @{
                           @"DefaultValue"   : [titles lastObject],
                           @"Title"          : NSLocalizedString(@"Image Size", @"Title of the screen for choosing an image's size."),
                           @"Titles"         : titles,
                           @"Values"         : values,
                           @"CurrentValue"   : currentValue
                           };

    NSDictionary *sizes = [self.post.blog getImageResizeDimensions];
    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:dict];
    __weak SettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *status) {
        CGSize maxSize = CGSizeZero;

        if ([status isEqualToString:@"thumbnail"]) {
            maxSize = [[sizes valueForKey:@"smallSize"] CGSizeValue];
        } else if ([status isEqualToString:@"medium"]) {
            maxSize = [[sizes valueForKey:@"mediumSize"] CGSizeValue];
        } else if ([status isEqualToString:@"large"]) {
            maxSize = [[sizes valueForKey:@"largeSize"] CGSizeValue];
        }

        self.imageDetails.width = @"";
        self.imageDetails.height = @"";

        // Don't set width/height if full size was selected.
        if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
            CGSize imageSize = [self imageSize];
            CGSize size = [self sizeForSize:imageSize withMaxSize:maxSize];
            if (size.width) {
                self.imageDetails.width = [NSString stringWithFormat:@"%d", (NSInteger)size.width];
            }
            if (size.height) {
                self.imageDetails.height = [NSString stringWithFormat:@"%d", (NSInteger)size.height];
            }
        }

        self.imageDetails.size = status;

        [weakVc dismiss];
        [self.tableView reloadData];
    };

    [self.navigationController pushViewController:vc animated:YES];
}

@end

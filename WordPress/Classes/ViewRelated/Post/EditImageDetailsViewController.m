#import "EditImageDetailsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <WordPressEditor/WPImageMeta.h>
#import <WordPressShared/UIImage+Util.h>
#import <WordPressShared/WPTextFieldTableViewCell.h>
#import "AbstractPost.h"
#import "SettingsSelectionViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "WPGUIConstants.h"
#import "WordPress-Swift.h"

static NSString *const TextFieldCell = @"TextFieldCell";
static NSString *const CellIdentifier = @"CellIdentifier";
static NSString *const ThumbCellIdentifier = @"ThumbCellIdentifier";
static CGFloat CellHeight = 44.0f;

typedef NS_ENUM(NSUInteger, ImageDetailsSection) {
    ImageDetailsSectionThumb,
    ImageDetailsSectionDetails,
    ImageDetailsSectionDisplay,
};

typedef NS_ENUM(NSUInteger, ImageDetailsRow) {
    ImageDetailsRowThumb,
    ImageDetailsRowTitle,
    ImageDetailsRowCaption,
    ImageDetailsRowAlt,
    ImageDetailsRowAlign,
    ImageDetailsRowLink,
    ImageDetailsRowSize
};

typedef NS_ENUM(NSUInteger, ImageDetailsTextField) {
    ImageDetailsTextFieldTitle,
    ImageDetailsTextFieldCaption,
    ImageDetailsTextFieldAlt,
    ImageDetailsTextFieldLink
};

@interface EditImageDetailsViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSArray *alignTitles;
@property (nonatomic, strong) NSArray *alignValues;
@property (nonatomic, strong) NSArray *sizeTitles;
@property (nonatomic, strong) NSArray *sizeValues;
@end

@implementation EditImageDetailsViewController

+ (instancetype)controllerForDetails:(WPImageMeta *)details forPost:(AbstractPost *)post
{
    EditImageDetailsViewController *controller = [EditImageDetailsViewController new];
    controller.imageDetails = details;
    controller.post = post;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Edit Image", @"Title of the edit image details screen.");

    [self.tableView registerClass:[WPTextFieldTableViewCell class] forCellReuseIdentifier:TextFieldCell];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ThumbCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
    self.tableView.accessibilityIdentifier = @"ImageDetailsTable";
    UIGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapInView:)];
    tgr.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tgr];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"The label of a close button in the image details view controller.")
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(handleCloseButtonTapped:)];
    self.navigationItem.leftBarButtonItem = button;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
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
    [self.sections addObject:[NSNumber numberWithInteger:ImageDetailsSectionThumb]];
    [self.sections addObject:[NSNumber numberWithInteger:ImageDetailsSectionDetails]];
    [self.sections addObject:[NSNumber numberWithInteger:ImageDetailsSectionDisplay]];
}


#pragma mark - Actions

- (void)handleCloseButtonTapped:(id)sender
{
    if ([UIDevice isOS8]) {
        // Update the delegate immediately for iOS 8 and later. This allows for a
        // better user experience as any changes should already be in place when the
        // editor reappears.
        [self.delegate editImageDetailsViewController:self didFinishEditingImageDetails:self.imageDetails];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // Update the delegate in the completion block. Avoids a race condition
        // on iOS7 that could lead to a crash in WebCore due to invalid geometry,
        // apparently caused by changes to the DOM during vc transition animation.
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate editImageDetailsViewController:self didFinishEditingImageDetails:self.imageDetails];
        }];
    }
}

- (void)handleTapInView:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}


#pragma mark - TextField Delegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == ImageDetailsTextFieldTitle) {
        self.imageDetails.title = textField.text;
    } else if (textField.tag == ImageDetailsTextFieldCaption) {
        self.imageDetails.caption = textField.text;
    } else if (textField.tag == ImageDetailsTextFieldAlt) {
        self.imageDetails.alt = textField.text;
    } else if (textField.tag == ImageDetailsTextFieldLink) {
        self.imageDetails.linkURL = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *str = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField.tag == ImageDetailsTextFieldTitle) {
        self.imageDetails.title = str;
    } else if (textField.tag == ImageDetailsTextFieldCaption) {
        self.imageDetails.caption = str;
    } else if (textField.tag == ImageDetailsTextFieldAlt) {
        self.imageDetails.alt = str;
    } else if (textField.tag == ImageDetailsTextFieldLink) {
        self.imageDetails.linkURL = str;
    }
    return YES;
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
    if (sec == ImageDetailsSectionThumb) {
        return 1;

    } else if (sec == ImageDetailsSectionDetails) {
        return 3;

    } else if (sec == ImageDetailsSectionDisplay) {
        return 3;
    }

    return 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == ImageDetailsSectionDetails) {
        return NSLocalizedString(@"Details", @"The title of the option group for editing an image's title, caption, etc. on the image details screen.");

    } else if (sec == ImageDetailsSectionDisplay) {
        return NSLocalizedString(@"Web Display Settings", @"The title of the option group for editing an image's size, alignment, etc. on the image details screen.");
    }

    return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return WPTableViewTopMargin;
    }

    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Remove extra padding caused by section footers in grouped table views
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];

    UITableViewCell *cell;

    if (sec == ImageDetailsSectionThumb) {
        // cofigure the thumb
        cell = [self thumbCellForIndexPath:indexPath];
    } else if (sec == ImageDetailsSectionDetails) {
        // return a textfield cell
        cell = [self detailCellForIndexPath:indexPath];
    } else if (sec == ImageDetailsSectionDisplay) {
        // display cells are textfields or normal cell
        cell = [self displayCellForIndexPath:indexPath];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if (cell.tag == ImageDetailsRowAlign) {
        [self showAlignmentSelector];
    } else if (cell.tag == ImageDetailsRowSize) {
        [self showSizeSelector];
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

- (UITableViewCell *)detailCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTextFieldTableViewCell *cell = [self getTextFieldCell];

    if (indexPath.row == 0) {
        cell.tag = ImageDetailsRowTitle;
        cell.textLabel.text = NSLocalizedString(@"Title", @"Label for the title field.");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Add a title", @"Placeholder text for the tags field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        cell.textField.accessibilityIdentifier = @"title value";
        cell.textField.text = self.imageDetails.title;
        cell.textField.tag = ImageDetailsTextFieldTitle;

    } else if (indexPath.row == 1) {
        cell.tag = ImageDetailsRowCaption;
        cell.textLabel.text = NSLocalizedString(@"Caption", @"Label for the caption field");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Add a caption", @"Placeholder text for the tags field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        cell.textField.accessibilityIdentifier = @"caption value";
        cell.textField.text = self.imageDetails.caption;
        cell.textField.tag = ImageDetailsTextFieldCaption;

    } else if (indexPath.row == 2) {
        cell.tag = ImageDetailsRowAlt;
        cell.textLabel.text = NSLocalizedString(@"Alt Text", @"Label for the image's alt attribute.");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Add alt text", @"Placeholder text for the tags field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        cell.textField.accessibilityIdentifier = @"alt text value";
        cell.textField.text = self.imageDetails.alt;
        cell.textField.tag = ImageDetailsTextFieldAlt;
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
        cell = [self linkCellForIndexPath:indexPath];
        cell.tag = ImageDetailsRowLink;
        ((WPTextFieldTableViewCell *)cell).textField.tag = ImageDetailsTextFieldLink;

    } else if (indexPath.row == 2) {
        cell.tag = ImageDetailsRowSize;
        cell.textLabel.text = NSLocalizedString(@"Size", @"Image size option title");
        cell.detailTextLabel.text = [self titleForSize:self.imageDetails.size];
        [WPStyleGuide configureTableViewCell:cell];
    }

    return cell;
}

- (UITableViewCell *)linkCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTextFieldTableViewCell *cell = [self getTextFieldCell];
    cell.tag = ImageDetailsRowLink;
    cell.textLabel.text = NSLocalizedString(@"Link To", @"Image link option title");
    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"http://www.example.com/", @"Placeholder text for the link field.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
    cell.textField.accessibilityIdentifier = @"title value";
    cell.textField.text = self.imageDetails.linkURL;
    cell.textField.tag = 0;

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

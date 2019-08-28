#import "RelatedPostsSettingsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "SettingTableViewCell.h"
#import "SVProgressHud+Dismiss.h"
#import "RelatedPostsPreviewTableViewCell.h"

#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"


static const CGFloat RelatePostsSettingsCellHeight = 44;

typedef NS_ENUM(NSInteger, RelatedPostsSettingsSection) {
    RelatedPostsSettingsSectionOptions = 0,
    RelatedPostsSettingsSectionPreview,
    RelatedPostsSettingsSectionCount
};

typedef NS_ENUM(NSInteger, RelatedPostsSettingsOptions) {
    RelatedPostsSettingsOptionsEnabled = 0,
    RelatedPostsSettingsOptionsShowHeader,
    RelatedPostsSettingsOptionsShowThumbnails,
    RelatedPostsSettingsOptionsCount,
};

@interface RelatedPostsSettingsViewController()

@property (nonatomic, strong) Blog *blog;

@property (nonatomic, strong) SwitchTableViewCell *relatedPostsEnabledCell;
@property (nonatomic, strong) SwitchTableViewCell *relatedPostsShowHeaderCell;
@property (nonatomic, strong) SwitchTableViewCell *relatedPostsShowThumbnailsCell;

@property (nonatomic, strong) RelatedPostsPreviewTableViewCell *relatedPostsPreviewTableViewCell;

@end

@implementation RelatedPostsSettingsViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.navigationItem.title = NSLocalizedString(@"Related Posts", @"Title for screen that allows configuration of your blog/site related posts settings.");
    self.tableView.allowsSelection = NO;
}


#pragma mark - Properties

- (BlogSettings *)settings
{
    return self.blog.settings;
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.settings.relatedPostsEnabled) {
        return RelatedPostsSettingsSectionCount;
    } else {
        return RelatedPostsSettingsSectionCount-1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            if (self.settings.relatedPostsEnabled) {
                return RelatedPostsSettingsOptionsCount;
            } else {
                return 1;
            }
        }
        break;
        case RelatedPostsSettingsSectionPreview:
            return 1;
        break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionPreview:
            return NSLocalizedString(@"Preview", @"Section title for related posts section preview");
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:
            return NSLocalizedString(@"Related Posts displays relevant content from your site below your posts", @"Information of what related post are and how they are presented");;
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case RelatedPostsSettingsSectionOptions:{
            return RelatePostsSettingsCellHeight;
        }
            break;
        case RelatedPostsSettingsSectionPreview:{
            return [self.relatedPostsPreviewTableViewCell heightForWidth:tableView.frame.size.width];
        }
            break;
        case RelatedPostsSettingsSectionCount:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RelatedPostsSettingsSection section = (RelatedPostsSettingsSection)indexPath.section;
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            RelatedPostsSettingsOptions row = indexPath.row;
            return [self tableView:tableView cellForOptionsRow:row];
            }
        break;
        case RelatedPostsSettingsSectionPreview:{
            return [self relatedPostsPreviewTableViewCell];
            }
        break;
        case RelatedPostsSettingsSectionCount:
        break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForOptionsRow:(RelatedPostsSettingsOptions)row
{
    switch (row) {
        case RelatedPostsSettingsOptionsEnabled:{
            self.relatedPostsEnabledCell.on = self.settings.relatedPostsEnabled;
            return self.relatedPostsEnabledCell;
        }
            break;
        case RelatedPostsSettingsOptionsShowHeader:{
            self.relatedPostsShowHeaderCell.on = self.settings.relatedPostsShowHeadline;
            return self.relatedPostsShowHeaderCell;
        }
            break;
        case RelatedPostsSettingsOptionsShowThumbnails:{
            self.relatedPostsShowThumbnailsCell.on = self.settings.relatedPostsShowThumbnails;
            return self.relatedPostsShowThumbnailsCell;
        }
            break;
        case RelatedPostsSettingsOptionsCount:
            break;
    }
    return nil;
}


#pragma mark - Cell Helpers

- (SwitchTableViewCell *)relatedPostsEnabledCell
{
    if (!_relatedPostsEnabledCell) {
        _relatedPostsEnabledCell = [SwitchTableViewCell new];
        _relatedPostsEnabledCell.name = NSLocalizedString(@"Show Related Posts", @"Label for configuration switch to enable/disable related posts");
        __weak RelatedPostsSettingsViewController *weakSelf = self;
        _relatedPostsEnabledCell.onChange = ^(BOOL value){
            [weakSelf updateRelatedPostsSettings:nil];
        };
    }
    return _relatedPostsEnabledCell;
}

- (SwitchTableViewCell *)relatedPostsShowHeaderCell
{
    if (!_relatedPostsShowHeaderCell) {
        _relatedPostsShowHeaderCell = [SwitchTableViewCell new];
        _relatedPostsShowHeaderCell.name = NSLocalizedString(@"Show Header", @"Label for configuration switch to show/hide the header for the related posts section");
        __weak RelatedPostsSettingsViewController *weakSelf = self;
        _relatedPostsShowHeaderCell.onChange = ^(BOOL value){
            [weakSelf updateRelatedPostsSettings:nil];
        };
    }

    return _relatedPostsShowHeaderCell;
}

- (SwitchTableViewCell *)relatedPostsShowThumbnailsCell
{
    if (!_relatedPostsShowThumbnailsCell) {
        _relatedPostsShowThumbnailsCell = [SwitchTableViewCell new];
        _relatedPostsShowThumbnailsCell.name = NSLocalizedString(@"Show Images", @"Label for configuration switch to show/hide images thumbnail for the related posts");
        __weak RelatedPostsSettingsViewController *weakSelf = self;
        _relatedPostsShowThumbnailsCell.onChange = ^(BOOL value){
            [weakSelf updateRelatedPostsSettings:nil];
        };
    }

    return _relatedPostsShowThumbnailsCell;
}


- (RelatedPostsPreviewTableViewCell *)relatedPostsPreviewTableViewCell
{
    if (!_relatedPostsPreviewTableViewCell) {
        _relatedPostsPreviewTableViewCell = [[RelatedPostsPreviewTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                                    reuseIdentifier:nil];
    }
    _relatedPostsPreviewTableViewCell.enabledImages = self.settings.relatedPostsShowThumbnails;
    _relatedPostsPreviewTableViewCell.enabledHeader = self.settings.relatedPostsShowHeadline;
    
    return _relatedPostsPreviewTableViewCell;

}

#pragma mark - Helpers

- (IBAction)updateRelatedPostsSettings:(id)sender
{
    self.settings.relatedPostsEnabled = self.relatedPostsEnabledCell.on;
    self.settings.relatedPostsShowHeadline = self.relatedPostsShowHeaderCell.on;
    self.settings.relatedPostsShowThumbnails = self.relatedPostsShowThumbnailsCell.on;
    
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService updateSettingsForBlog:self.blog success:^{
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Settings update failed", @"Message to show when setting save failed")];
        [self.tableView reloadData];
    }];
    [self.tableView reloadData];
}

@end

#import "RelatedPostsSettingsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "SettingTableViewCell.h"
#import "RelatedPostsPreviewTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "WPStyleGuide+ReadableMargins.h"

#import <WordPressShared/WPStyleGuide.h>
#import <SVProgressHUD/SVProgressHUD.h>
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
    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            WPTableViewSectionHeaderFooterView *headerView = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
            return headerView;
        }
            break;
        case RelatedPostsSettingsSectionPreview:{
            WPTableViewSectionHeaderFooterView *headerView = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
            headerView.title = NSLocalizedString(@"Preview", @"Section title for related posts section preview");
            return headerView;
        }
            break;
        case RelatedPostsSettingsSectionCount:
            break;
    }
    return nil;

}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            WPTableViewSectionHeaderFooterView *footerView = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil
                                                                                                                           style:WPTableViewSectionStyleFooter];
            footerView.title = NSLocalizedString(@"Related Posts displays relevant content from your site below your posts", @"Information of what related post are and how they are presented");
            return footerView;
        }
            break;
        case RelatedPostsSettingsSectionPreview:{
            WPTableViewSectionHeaderFooterView *footerView = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil
                                                                                                                           style:WPTableViewSectionStyleFooter];
            return footerView;
        }
            break;
        case RelatedPostsSettingsSectionCount:
            break;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            return [WPTableViewSectionHeaderFooterView heightForHeader:@"" width:tableView.frame.size.width];
        }
            break;
        case RelatedPostsSettingsSectionPreview:{
            return [WPTableViewSectionHeaderFooterView heightForHeader:NSLocalizedString(@"Preview", @"Section title for related posts section preview") width:tableView.frame.size.width];
        }
            break;
        case RelatedPostsSettingsSectionCount:
            break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    switch (section) {
        case RelatedPostsSettingsSectionOptions:{
            return [WPTableViewSectionHeaderFooterView heightForFooter:NSLocalizedString(@"Related Posts displays relevant content from your site below your posts.", @"Information of what related post are and how they are presented.")
                                                                 width:tableView.frame.size.width];
        }
            break;
        case RelatedPostsSettingsSectionPreview:{
            return [WPTableViewSectionHeaderFooterView heightForFooter:@"" width:tableView.frame.size.width];
        }
            break;
        case RelatedPostsSettingsSectionCount:
            break;
    }
    return 0;
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
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Settings update failed", @"Message to show when setting save failed")];
        [self.tableView reloadData];
    }];
    [self.tableView reloadData];
}

@end

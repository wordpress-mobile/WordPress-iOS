#import "RelatedPostsSettingsViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "SwitchSettingTableViewCell.h"
#import "SettingTableViewCell.h"
#import "RelatedPostsPreviewTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "WPStyleGuide+ReadableMargins.h"

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

@property (nonatomic, strong) SwitchSettingTableViewCell *relatedPostsEnabledCell;
@property (nonatomic, strong) SwitchSettingTableViewCell *relatedPostsShowHeaderCell;
@property (nonatomic, strong) SwitchSettingTableViewCell *relatedPostsShowThumbnailsCell;

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
            self.relatedPostsEnabledCell.switchValue = self.settings.relatedPostsEnabled;
            return self.relatedPostsEnabledCell;
        }
            break;
        case RelatedPostsSettingsOptionsShowHeader:{
            self.relatedPostsShowHeaderCell.switchValue = self.settings.relatedPostsShowHeadline;
            return self.relatedPostsShowHeaderCell;
        }
            break;
        case RelatedPostsSettingsOptionsShowThumbnails:{
            self.relatedPostsShowThumbnailsCell.switchValue = self.settings.relatedPostsShowThumbnails;
            return self.relatedPostsShowThumbnailsCell;
        }
            break;
        case RelatedPostsSettingsOptionsCount:
            break;
    }
    return nil;
}


#pragma mark - Cell Helpers

- (SwitchSettingTableViewCell *)relatedPostsEnabledCell
{
    if (!_relatedPostsEnabledCell) {
        _relatedPostsEnabledCell = [[SwitchSettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Show Related Posts", @"Label for configuration switch to enable/disable related posts")
                                                                              target:self
                                                                              action:@selector(updateRelatedPostsSettings:)
                                                                     reuseIdentifier:nil];
    }
    return _relatedPostsEnabledCell;
}

- (SwitchSettingTableViewCell *)relatedPostsShowHeaderCell
{
    if (!_relatedPostsShowHeaderCell) {
        _relatedPostsShowHeaderCell = [[SwitchSettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Show Header", @"Label for configuration switch to show/hide the header for the related posts section")
                                                                              target:self
                                                                              action:@selector(updateRelatedPostsSettings:)
                                                                     reuseIdentifier:nil];
    }

    return _relatedPostsShowHeaderCell;
}

- (SwitchSettingTableViewCell *)relatedPostsShowThumbnailsCell
{
    if (!_relatedPostsShowThumbnailsCell) {
        _relatedPostsShowThumbnailsCell = [[SwitchSettingTableViewCell alloc] initWithLabel:NSLocalizedString(@"Show Images", @"Label for configuration switch to show/hide images thumbnail for the related posts")
                                                                              target:self
                                                                              action:@selector(updateRelatedPostsSettings:)
                                                                     reuseIdentifier:nil];
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
    self.settings.relatedPostsEnabled = self.relatedPostsEnabledCell.switchValue;
    self.settings.relatedPostsShowHeadline = self.relatedPostsShowHeaderCell.switchValue;
    self.settings.relatedPostsShowThumbnails = self.relatedPostsShowThumbnailsCell.switchValue;
    
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

#import "PageSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "WordPress-Swift.h"

@interface PageSettingsViewController ()

@property (nonatomic, strong, readonly, nonnull) ParentPagesController *parentPagesController;

@end

@implementation PageSettingsViewController

#pragma mark - Properties

- (Page *)page
{
    if ([self.apost isKindOfClass:[Page class]]) {
        return (Page *)self.apost;
    }
    
    return nil;
}

#pragma mark - Init

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [super initWithPost:aPost];
    if (self && self.page && self.page.blog) {
        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
        _parentPagesController = [[ParentPagesController alloc] initWithBlog: self.page.blog managedObjectContext:mainContext];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [self.parentPagesController refreshPages];
    [super viewWillAppear: animated];
}

#pragma mark - Table Configuration

- (void)configureSections
{
    self.sections = @[@(PostSettingsSectionMeta),@(PostSettingsSectionFeaturedImage)];
}

- (void)configureMetaSectionRows
{
    [super configureMetaSectionRows];
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self.postMetaSectionRows];
    [mutableArray addObject: @(PostSettingsRowParent)];
    self.postMetaSectionRows = [mutableArray copy];
}

- (UITableViewCell *)configureMetaPostMetaCellForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [[self.postMetaSectionRows objectAtIndex:indexPath.row] integerValue];
    if (row == PostSettingsRowParent) {
        Page *parentPage = [self.parentPagesController selectedParentForPage:self.page];
        UITableViewCell *cell = [self getWPTableViewDisclosureCell];
        cell.textLabel.text = NSLocalizedString(@"Set Parent", @"Label for a row that opens the Set Parent options view controller");
        cell.accessibilityIdentifier = @"SetParentPage";
        cell.detailTextLabel.text = parentPage ? parentPage.postTitle : @"";
        cell.tag = PostSettingsRowParent;
        return cell;
    }
    return [super configureMetaPostMetaCellForIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.tag == PostSettingsRowParent) {
        [self showSetParentController];
    }
}

#pragma mark - User Interaction

- (void)showSetParentController
{
    NSArray<Page *> *pages = [self.parentPagesController availableParentsForEditingForPage:self.page];
    ParentPageSettingsViewController *controller = [ParentPageSettingsViewController fromStoryboardWith:pages selectedPage:self.page];
    controller.uploadChangesOnSave = false;
    controller.dismissOnItemSelected = true;
    if (self.navigationController) {
        [self.navigationController pushViewController:controller animated:true];
    }
}

@end

#import "NotificationDetailsViewController.h"
#import "NotificationDetailsViewController+Internal.h"

#import "Blog.h"
#import "Notification.h"

#import "ContextManager.h"

#import "SuggestionsTableView.h"

#import "AppRatingUtility.h"

#import "WordPress-Swift.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"
#import "NSObject+Helpers.h"
#import "NSDate+StringFormatting.h"
#import "NSString+Helpers.h"



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSInteger NotificationSectionCount = 1;



#pragma mark ==========================================================================================
#pragma mark NotificationDetailsViewController
#pragma mark ==========================================================================================

@implementation NotificationDetailsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Failsafe: Manually nuke the tableView dataSource and delegate. Make sure not to force a loadView event!
    if (!self.isViewLoaded) {
        return;
    }
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.restorationClass = [self class];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    [self setupMainView];
    [self setupTableView];
    [self setupTableViewCells];
    [self setupMediaDownloader];
    [self setupReplyTextView];
    [self setupSuggestionsView];
    [self setupKeyboardManager];
    [self setupNotificationListeners];

    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectSelectedRowWithAnimation:YES];
    [self.keyboardManager startListeningToKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.keyboardManager stopListeningToKeyboardNotifications];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self adjustLayoutConstraintsIfNeeded];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self.tableView reloadData];
    [self adjustLayoutConstraintsIfNeeded];
}

- (void)reloadData
{
    // Hide the header, if needed
    NSMutableArray *blockGroups = [NSMutableArray array];
    
    if (_note.headerBlockGroup) {
        [blockGroups addObject:_note.headerBlockGroup];
    }
    
    if (_note.bodyBlockGroups) {
        [blockGroups addObjectsFromArray:_note.bodyBlockGroups];
    }
    
    self.blockGroups = blockGroups;
    
    // Reload UI
    self.title = self.note.title;
    [self.tableView reloadData];
    [self adjustLayoutConstraintsIfNeeded];
}


#pragma mark - Public Helpers

- (void)setupWithNotification:(Notification *)notification
{
    self.note = notification;
    [self loadViewIfNeeded];
    [self attachReplyViewIfNeeded];
    [self attachSuggestionsViewIfNeeded];
    [self attachEditActionIfNeeded];
    [self reloadData];
}


#pragma mark - Autolayout Helpers

- (NSDictionary *)layoutIdentifierMap
{
    if (_layoutIdentifierMap) {
        return _layoutIdentifierMap;
    }
    
    _layoutIdentifierMap = @{
        @(NoteBlockGroupTypeHeader)    : NoteBlockHeaderTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeFooter)    : NoteBlockTextTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeText)      : NoteBlockTextTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeComment)   : NoteBlockCommentTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeActions)   : NoteBlockActionsTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeImage)     : NoteBlockImageTableViewCell.layoutIdentifier,
        @(NoteBlockGroupTypeUser)      : NoteBlockUserTableViewCell.layoutIdentifier
    };
    
    return _layoutIdentifierMap;
}

- (NSDictionary *)reuseIdentifierMap
{
    return @{
        @(NoteBlockGroupTypeHeader)     : NoteBlockHeaderTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeFooter)     : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeText)       : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeComment)    : NoteBlockCommentTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeActions)    : NoteBlockActionsTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeImage)      : NoteBlockImageTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeUser)       : NoteBlockUserTableViewCell.reuseIdentifier
    };
}




#pragma mark - UIViewController Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSString *noteID = [coder decodeObjectForKey:NSStringFromClass([Notification class])];
    if (!noteID) {
        return nil;
    }
    
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:noteID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    Notification *restoredNotification = (Notification *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredNotification) {
        return nil;
    }
    
    UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
    if (!storyboard) {
        return nil;
    }
    
    NotificationDetailsViewController *vc   = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.restorationIdentifier                = [identifierComponents lastObject];
    vc.restorationClass                     = [NotificationDetailsViewController class];
    
    [vc setupWithNotification:restoredNotification];
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *noteIdKey = NSStringFromClass([Notification class]);
    [coder encodeObject:[self.note.objectID.URIRepresentation absoluteString] forKey:noteIdKey];
    [super encodeRestorableStateWithCoder:coder];
}


#pragma mark - Helpers

- (NotificationBlockGroup *)blockGroupForIndexPath:(NSIndexPath *)indexPath
{
    return self.blockGroups[indexPath.row];
}


#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NotificationSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.blockGroups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NSString *layoutIdentifier              = self.layoutIdentifierMap[@(blockGroup.type)] ?: self.layoutIdentifierMap[@(NoteBlockGroupTypeText)];
    NoteBlockTableViewCell *tableViewCell   = [tableView dequeueReusableCellWithIdentifier:layoutIdentifier];

    [self downloadAndResizeMedia:indexPath blockGroup:blockGroup];
    [self setupCell:tableViewCell blockGroup:blockGroup];
    
    CGFloat height = [tableViewCell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];

    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NSString *reuseIdentifier               = self.reuseIdentifierMap[@(blockGroup.type)] ?: self.reuseIdentifierMap[@(NoteBlockGroupTypeText)];
    NoteBlockTableViewCell *cell            = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    [self setupSeparators:cell indexPath:indexPath];
    [self setupCell:cell blockGroup:blockGroup];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *group = [self blockGroupForIndexPath:indexPath];

    // Header-Level: Push the resource associated with the note
    if (group.type == NoteBlockGroupTypeHeader) {
        [self displayNotificationSource];

    // User-Level: Push the associated blog, if any
    } else if (group.type == NoteBlockGroupTypeUser) {
        NSURL *targetURL = [[group blockOfType:NoteBlockTypeUser] metaLinksHome];
        [self displayURL:targetURL];

    // Footer-Level: By convention, the last range is the one that always contains the targetURL
    } else if (group.type == NoteBlockGroupTypeFooter) {
        NSURL *targetURL = [[[[group blockOfType:NoteBlockTypeText] ranges] lastObject] url];
        [self displayURL:targetURL];
    }
}

@end

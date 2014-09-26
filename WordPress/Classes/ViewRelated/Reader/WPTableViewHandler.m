#import "WPTableViewHandler.h"
#import "WPTableViewSectionHeaderView.h"
#import "WPTableViewCell.h"

static NSString * const DefaultCellIdentifier = @"DefaultCellIdentifier";
static CGFloat const DefaultCellHeight = 44.0;

@interface WPTableViewHandler ()

@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong, readwrite) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSIndexPath *indexPathSelectedBeforeUpdates;
@property (nonatomic, strong) NSIndexPath *indexPathSelectedAfterUpdates;
@property (nonatomic, strong) NSMutableArray *sectionHeaders;
@property (nonatomic, strong) NSMutableDictionary *cachedRowHeights;

@end

@implementation WPTableViewHandler

#pragma mark - LifeCycle Methods

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        _sectionHeaders = [NSMutableArray array];
        _cachedRowHeights = [NSMutableDictionary dictionary];

        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:DefaultCellIdentifier];
    }
    return self;
}


#pragma mark - Public Methods

- (void)updateTitleForSection:(NSUInteger)section
{
    WPTableViewSectionHeaderView *sectionHeaderView = (WPTableViewSectionHeaderView *)[self tableView:self.tableView viewForHeaderInSection:section];
    sectionHeaderView.title = [self titleForHeaderInSection:section];
}

- (void)clearCachedRowHeights
{
    [self.cachedRowHeights removeAllObjects];
}


#pragma mark - Private Methods

- (void)cacheHeight:(CGFloat)height forIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i|%i", indexPath.section, indexPath.row];
    [self.cachedRowHeights setObject:@(height) forKey:key];
}

- (CGFloat)cachedHeightForIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i|%i", indexPath.section, indexPath.row];
    return [[self.cachedRowHeights numberForKey:key] floatValue];
}

- (void)refreshCachedRowHeightsForWidth:(CGFloat)width
{
    if (!self.cacheRowHeights || ![self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:forWidth:)]) {
        return;
    }

    NSMutableDictionary *cachedRowHeights = [NSMutableDictionary dictionary];
    for (NSObject *obj in self.resultsController.fetchedObjects) {
        NSIndexPath *indexPath = [self.resultsController indexPathForObject:obj];
        CGFloat height = [self.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath forWidth:width];

        NSString *key = [NSString stringWithFormat:@"%i|%i", indexPath.section, indexPath.row];
        [cachedRowHeights setObject:@(height) forKey:key];
    }

    self.cachedRowHeights = cachedRowHeights;
}


#pragma mark - Required Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [self.delegate managedObjectContext];
}

- (NSFetchRequest *)fetchRequest
{
    return [self.delegate fetchRequest];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate configureCell:cell atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}


#pragma mark - Optional Delegate Methods

- (NSString *)sectionNameKeyPath
{
    if ([self.delegate respondsToSelector:@selector(sectionNameKeyPath)]) {
        return [self.delegate sectionNameKeyPath];
    }
    return nil;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(titleForHeaderInSection:)]) {
        return [self.delegate titleForHeaderInSection:section];
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
        return [self.delegate tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [self.delegate tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
        return [self.delegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
    }
    return UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        return [self.delegate tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];

    if (self.tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)]) {
        return [self.delegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(deletingSelectedRowAtIndexPath:)]) {
        [self.delegate deletingSelectedRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = DefaultCellHeight;

    if (self.cacheRowHeights) {
        height = [self cachedHeightForIndexPath:indexPath];
        if (height) {
            return height;
        }
    }

    if ([self.delegate respondsToSelector:@selector(tableView:estimatedHeightForRowAtIndexPath:)]) {
        height = [self.delegate tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }

    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = DefaultCellHeight;

    if (self.cacheRowHeights) {
        height = [self cachedHeightForIndexPath:indexPath];
        if (height) {
            return height;
        }
    }

    if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        height = [self.delegate tableView:tableView heightForRowAtIndexPath:indexPath];
        if (self.cacheRowHeights) {
            [self cacheHeight:height forIndexPath:indexPath];
        }
    }

    return height;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:shouldHighlightRowAtIndexPath:)]) {
        return [self.delegate tableView:tableView shouldHighlightRowAtIndexPath:indexPath];
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
        [self.delegate tableView:tableView willSelectRowAtIndexPath:indexPath];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [self.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [self.delegate tableView:tableView viewForHeaderInSection:section];
    }

    if ([self.sectionHeaders count] > section) {
        return [self.sectionHeaders objectAtIndex:section];
    }
    CGRect frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 0.0);
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:frame];
    header.title = [self titleForHeaderInSection:section];
    [self.sectionHeaders addObject:header];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [self.delegate tableView:tableView heightForHeaderInSection:section];
    }

    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.tableView.bounds)];
}


#pragma mark - TableView Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}


#pragma mark - TableView Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // remove footer height for all but last section
    return section == [[self.resultsController sections] count] - 1 ? UITableViewAutomaticDimension : 1.0;
}


#pragma mark - Fetched results controller

- (UITableViewRowAnimation)tableViewRowAnimation
{
    return UITableViewRowAnimationFade;
}

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController != nil) {
        return _resultsController;
    }

    NSFetchRequest *fetchRequest = [self fetchRequest];
    if (!fetchRequest) {
        return nil;
    }
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                             managedObjectContext:moc
                                                               sectionNameKeyPath:[self sectionNameKeyPath]
                                                                        cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"%@ couldn't fetch %@: %@", self, [[self fetchRequest] entityName], [error localizedDescription]);
        _resultsController = nil;
    }

    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(tableViewWillChangeContent:)]) {
        [self.delegate tableViewWillChangeContent:self.tableView];
    }

    self.indexPathSelectedBeforeUpdates = [self.tableView indexPathForSelectedRow];
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    if (self.indexPathSelectedAfterUpdates) {
        [self.tableView selectRowAtIndexPath:_indexPathSelectedAfterUpdates animated:NO scrollPosition:UITableViewScrollPositionNone];

        self.indexPathSelectedBeforeUpdates = nil;
        self.indexPathSelectedAfterUpdates = nil;
    }

    if ([self.delegate respondsToSelector:@selector(tableViewDidChangeContent:)]) {
        [self.delegate tableViewDidChangeContent:self.tableView];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    if (NSFetchedResultsChangeUpdate == type && newIndexPath && ![newIndexPath isEqual:indexPath]) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    if (newIndexPath == nil) {
        // It seems in some cases newIndexPath can be nil for updates
        newIndexPath = indexPath;
    }

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:[self tableViewRowAnimation]];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:[self tableViewRowAnimation]];
            if ([_indexPathSelectedBeforeUpdates isEqual:indexPath]) {
                [self deletingSelectedRowAtIndexPath:indexPath];
            }
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:[self tableViewRowAnimation]];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:[self tableViewRowAnimation]];
            if ([_indexPathSelectedBeforeUpdates isEqual:indexPath] && _indexPathSelectedAfterUpdates == nil) {
                _indexPathSelectedAfterUpdates = newIndexPath;
            }
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self tableViewRowAnimation]];
    } else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:[self tableViewRowAnimation]];
    }
}

@end

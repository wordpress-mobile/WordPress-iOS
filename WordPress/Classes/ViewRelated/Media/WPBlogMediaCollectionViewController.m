#import "WPBlogMediaCollectionViewController.h"
#import "WPBlogMediaCollectionViewCell.h"
#import "WPBlogMediaPickerViewController.h"
#import "Media.h"
#import "Blog.h"
#import "ContextManager.h"
#import "MediaService.h"

@interface WPBlogMediaCollectionViewController () <UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *selected;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (atomic, assign) NSInteger thumbnailsLoading;
@property (nonatomic, strong) MediaService *loader;

@end

@implementation WPBlogMediaCollectionViewController

static CGFloat const SelectAnimationTime = 0.2;
static NSString * const ArrowDown = @"\u25be";

+ (NSString *)title
{
    NSString *optionBlog = NSLocalizedString(@"Blog Media", @"Image source: blog");
    return optionBlog;
}

- (NSString *)title
{
    return [[self class] title];
}

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self){
        _layout = layout;
        _selected = [[NSMutableArray alloc] init];
        _showMostRecentFirst = NO;
        _objectChanges = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure collection view behaviour
    self.clearsSelectionOnViewWillAppear = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    // Register cell class
    [self.collectionView registerClass:[WPBlogMediaCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPBlogMediaCollectionViewCell class])];
    
    // Configure collection view layout
    CGFloat spaceBetweenPhotos = [Media preferredThumbnailSpacing];
    CGFloat width = [Media thumbnailWidthFor:self.view.frame.size.width];
    self.layout.itemSize = CGSizeMake(width, width);
    self.layout.minimumInteritemSpacing = spaceBetweenPhotos;
    self.layout.minimumLineSpacing = spaceBetweenPhotos;
    self.layout.sectionInset = UIEdgeInsetsMake(spaceBetweenPhotos, 0, spaceBetweenPhotos, 0);
    
    //setup navigation items
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelPicker:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(finishPicker:)];

    // Fetch Media for this blog
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSAssert(NO, @"Media fetch error %@, %@", error, [error userInfo]);
    }
}

#pragma mark - Actions

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]){
        [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
    }
}

- (void)finishPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingMedia:)]){
        [self.picker.delegate mediaPickerController:self.picker didFinishPickingMedia:[self.selected copy]];
    }
   
}

- (WPBlogMediaPickerViewController *)picker
{
    return (WPBlogMediaPickerViewController *)self.navigationController.parentViewController;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][(NSUInteger)section];
    return (NSInteger)[sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // load the Media for this cell
    Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    WPBlogMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPBlogMediaCollectionViewCell class]) forIndexPath:indexPath];
    
    // Configure the cell
    if (media.thumbnail) {
        cell.image = [UIImage imageWithData:media.thumbnail];
    } else {
        [self loadVisibleMedia];
    }
    
    NSUInteger position = [self findMedia:media];
    if (position != NSNotFound){
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [cell setPosition:position+1];
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }
    
    NSString *caption = media.filename;
    [cell setCaption:caption];
    
    return cell;
}

- (NSUInteger)findMedia:(Media *)media
{
    NSUInteger position = [self.selected indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Media * loopMedia = (Media *)obj;
        BOOL found = [media.mediaID isEqual:loopMedia.mediaID];
        return found;
    }];
    return position;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectMedia:)]){
        return [self.picker.delegate mediaPickerController:self.picker shouldSelectMedia:media];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self.selected addObject:media];
    WPBlogMediaCollectionViewCell * cell = (WPBlogMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setPosition:self.selected.count];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didSelectMedia:)]){
        [self.picker.delegate mediaPickerController:self.picker didSelectMedia:media];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectMedia:)]){
        return [self.picker.delegate mediaPickerController:self.picker shouldDeselectMedia:media];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];

    
    NSUInteger deselectPosition = [self findMedia:media];
    if(deselectPosition != NSNotFound) {
        [self.selected removeObjectAtIndex:deselectPosition];
    }
    
    WPBlogMediaCollectionViewCell * cell = (WPBlogMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForSelectedItems];
    }];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didDeselectMedia:)]){
        [self.picker.delegate mediaPickerController:self.picker didDeselectMedia:media];
    }
}

- (void)animateCellSelection:(UIView *)cell completion:(void(^)())completionBlock
{
    [UIView animateKeyframesWithDuration:SelectAnimationTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, 1, 1);
        }];
        [UIView addKeyframeWithRelativeStartTime:SelectAnimationTime/2 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, -1, -1);
        }];
    } completion:^(BOOL finished) {
        if(completionBlock){
            completionBlock();
        }
    }];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSAssert(self.blog, @"Blog for media selection not set");
        NSManagedObjectContext *context = self.blog.managedObjectContext;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:!self.showMostRecentFirst]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog == %@ AND mediaTypeString == 'image'", self.blog];
        fetchRequest.predicate = predicate;
        fetchRequest.fetchBatchSize = 20;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = NSMutableDictionary.new;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [self.objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.objectChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in self.objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL * __unused stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    [self.objectChanges removeAllObjects];
}

-  (MediaService *)loader
{
    if (!_loader) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        _loader = [[MediaService alloc] initWithManagedObjectContext:context];
    }
    return _loader;
}

- (void)loadVisibleMedia
{
    const NSInteger MaxThumbnailLoads = 4;
    if (self.thumbnailsLoading >= MaxThumbnailLoads) {
        return;
    }
  
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        Media *media = (Media *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        if (!media.remoteURL.length || media.thumbnail || media.mediaType != MediaTypeImage) {
            continue;
        }

        self.thumbnailsLoading++;
        [self.loader getThumbnailForMedia:media
                                  success:^(UIImage *image) {
                                      self.thumbnailsLoading--;
                                      [self performSelector:@selector(loadVisibleMedia) withObject:nil afterDelay:0];
                                  }
                                  failure:^(NSError *error) {
                                      DDLogError(@"Failed getting thumbnail image: %@", error);
                                      self.thumbnailsLoading--;
                                      [self performSelector:@selector(loadVisibleMedia) withObject:nil afterDelay:0];
                                  }];
        if (self.thumbnailsLoading >= MaxThumbnailLoads) {
            return;
        }
    }
}

@end

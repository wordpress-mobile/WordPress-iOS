/*
 * ThemeBrowserViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeBrowserViewController.h"
#import "Theme.h"
#import "WordPressAppDelegate.h"
#import "ThemeBrowserCell.h"
#import "ThemeSearchFilterHeaderView.h"
#import "ThemeDetailsViewController.h"
#import "Blog.h"

static NSString *const ThemeCellIdentifier = @"theme";
static NSString *const SearchFilterCellIdentifier = @"search_filter";

@interface ThemeBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSBlockOperation *resultsChanges;
@property (nonatomic, strong) NSString *currentFilter;

@end

@implementation ThemeBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Themes", @"Title for Themes browser");
        self.currentFilter = @"themeId";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[ThemeBrowserCell class] forCellWithReuseIdentifier:ThemeCellIdentifier];
    [self.collectionView registerClass:[ThemeSearchFilterHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:SearchFilterCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Theme fetchAndInsertThemesForBlogId:self.blog.blogID.stringValue success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.fetchedResultsController = nil;
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [[sectionInfo objects] count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        ThemeSearchFilterHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:SearchFilterCellIdentifier forIndexPath:indexPath];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            header.delegate = self;
        });
        return header;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ThemeBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ThemeCellIdentifier forIndexPath:indexPath];
    cell.theme = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Theme *theme = [self.fetchedResultsController objectAtIndexPath:indexPath];
    ThemeDetailsViewController *details = [[ThemeDetailsViewController alloc] initWithTheme:theme];
    [self.navigationController pushViewController:details animated:true];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *context = [WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Theme class])];
    
    // TODO current sort that's applied
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:self.currentFilter ascending:YES]]];
    [fetchRequest setFetchBatchSize:10];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    NSError *error;
    if (![_fetchedResultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, NSStringFromClass([Theme class]), [error localizedDescription]);
        _fetchedResultsController = nil;
    }
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    self.resultsChanges = [NSBlockOperation new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//    __weak UICollectionView *collectionView = self.collectionView;
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//        {
//            [_resultsChanges addExecutionBlock:^{
//                [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
//                if ([collectionView numberOfItemsInSection:indexPath.section] == 0) {
//                    // First item, reload
//                    [collectionView reloadData];
//                }
//            }];
//            break;
//        }
//        case NSFetchedResultsChangeDelete:
//        {
//            [_resultsChanges addExecutionBlock:^{
//                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
//                if ([collectionView numberOfItemsInSection:indexPath.section] == 1) {
//                    // Last item, reload the collection view
//                    [collectionView reloadData];
//                }
//            }];
//            break;
//        }
//        case NSFetchedResultsChangeMove:
//        {
//            [_resultsChanges addExecutionBlock:^{
//                [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
//            }];
//            break;
//        }
//        case NSFetchedResultsChangeUpdate:
//        {
//            [_resultsChanges addExecutionBlock:^{
//                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
//            }];
//            break;
//        }
//        default:
//            break;
//    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.collectionView performBatchUpdates:^{
//        [_resultsChanges start];
//    } completion:nil];
    // TODO above isn't working atm, causes crazy malloc errors. Related to http://openradar.appspot.com/12954582 ?
    // Since we're loading all themes at once anyways, this doesn't change much.
    [self.collectionView reloadData];
}

@end

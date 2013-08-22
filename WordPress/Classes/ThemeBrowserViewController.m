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

static NSString *const cellIdentifier = @"theme";

@interface ThemeBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *searchFilterView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ThemeBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Themes", @"Title for Themes browser");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[ThemeBrowserCell class] forCellWithReuseIdentifier:cellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Theme fetchAndInsertThemesWithSuccess:^{
        // TODO dismiss loading and use NSFetchedResultsController instead
        [self.collectionView reloadData];
    } failure:^(NSError *error) {
        // TODO show error/dismiss loading
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ThemeBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.theme = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO Theme details
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *context = [WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Theme class])];
    
    // TODO current sort that's applied
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"themeId" ascending:YES]]];
    [fetchRequest setFetchBatchSize:10];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context sectionNameKeyPath:nil cacheName:@"themes"];
    _fetchedResultsController.delegate = self;
    NSError *error;
    if (![_fetchedResultsController performFetch:&error]) {
        WPFLog(@"%@ couldn't fetch %@: %@", self, NSStringFromClass([Theme class]), [error localizedDescription]);
        _fetchedResultsController = nil;
    }
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    // TODO queue individual changes for collection view and batch update as below
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // TODO propagate changes to UICollectionView with performBatchUpdates:
}

@end

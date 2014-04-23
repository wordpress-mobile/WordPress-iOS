/*
 CTAssetsGroupViewController.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsPickerConstants.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsGroupViewController.h"
#import "CTAssetsGroupViewCell.h"
#import "CTAssetsViewController.h"



@interface CTAssetsPickerController ()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

- (NSString *)toolbarTitle;
- (UIView *)notAllowedView;
- (UIView *)noAssetsView;

@end



@interface CTAssetsGroupViewController()

@property (nonatomic, weak) CTAssetsPickerController *picker;
@property (nonatomic, strong) NSMutableArray *groups;

@end





@implementation CTAssetsGroupViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.preferredContentSize = kPopoverContentSize;
        [self addNotificationObserver];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
    [self setupToolbar];
    [self localize];
    [self setupGroup];
}

- (void)dealloc
{
    [self removeNotificationObserver];
}


#pragma mark - Accessors

- (CTAssetsPickerController *)picker
{
    return (CTAssetsPickerController *)self.navigationController;
}


#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - Setup

- (void)setupViews
{
    self.tableView.rowHeight = kThumbnailLength + 12;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setupButtons
{
    if (self.picker.showsCancelButton)
    {
        self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self.picker
                                        action:@selector(dismiss:)];
    }
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                     style:UIBarButtonItemStyleDone
                                    target:self.picker
                                    action:@selector(finishPickingAssets:)];
    
    self.navigationItem.rightBarButtonItem.enabled = (self.picker.selectedAssets.count > 0);
}

- (void)setupToolbar
{
    self.toolbarItems = self.picker.toolbarItems;
}

- (void)localize
{
    if (!self.picker.title)
        self.title = NSLocalizedString(@"Photos", nil);
    else
        self.title = self.picker.title;
}

- (void)setupGroup
{
    if (!self.groups)
        self.groups = [[NSMutableArray alloc] init];
    else
        [self.groups removeAllObjects];
    
    ALAssetsFilter *assetsFilter = self.picker.assetsFilter;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (group)
        {
            [group setAssetsFilter:assetsFilter];
            
            BOOL shouldShowGroup;
            
            if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldShowAssetsGroup:)])
                shouldShowGroup = [self.picker.delegate assetsPickerController:self.picker shouldShowAssetsGroup:group];
            else
                shouldShowGroup = YES;
            
            if (shouldShowGroup)
                [self.groups addObject:group];
        }
        else
        {
            [self reloadData];
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error)
    {
        [self showNotAllowed];
    };
    
    // Enumerate Camera roll first
    [self.picker.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                             usingBlock:resultsBlock
                                           failureBlock:failureBlock];
    
    // Then all other groups
    NSUInteger type =
    ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
    ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
    
    [self.picker.assetsLibrary enumerateGroupsWithTypes:type
                                             usingBlock:resultsBlock
                                           failureBlock:failureBlock];
}


#pragma mark - Notifications

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(assetsLibraryChanged:)
                   name:ALAssetsLibraryChangedNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(selectedAssetsChanged:)
                   name:CTAssetsPickerSelectedAssetsChangedNotification
                 object:nil];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Assets Library Changed

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    // Reload all groups
    if (notification.userInfo == nil)
        [self performSelectorOnMainThread:@selector(setupGroup) withObject:nil waitUntilDone:NO];
    
    // Reload effected assets groups
    if (notification.userInfo.count > 0)
    {
        [self reloadAssetsGroupForUserInfo:notification.userInfo
                                       key:ALAssetLibraryUpdatedAssetGroupsKey
                                    action:@selector(updateAssetsGroupForURL:)];
        
        [self reloadAssetsGroupForUserInfo:notification.userInfo
                                       key:ALAssetLibraryInsertedAssetGroupsKey
                                    action:@selector(insertAssetsGroupForURL:)];
        
        [self reloadAssetsGroupForUserInfo:notification.userInfo
                                       key:ALAssetLibraryDeletedAssetGroupsKey
                                    action:@selector(deleteAssetsGroupForURL:)];
    }
}


#pragma mark - Reload Assets Group

- (void)reloadAssetsGroupForUserInfo:(NSDictionary *)userInfo key:(NSString *)key action:(SEL)selector
{
    NSSet *URLs = [userInfo objectForKey:key];
    
    for (NSURL *URL in URLs.allObjects)
        [self performSelectorOnMainThread:selector withObject:URL waitUntilDone:NO];
}

- (NSUInteger)indexOfAssetsGroupWithURL:(NSURL *)URL
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ALAssetsGroup *group, NSDictionary *bindings){
        return [[group valueForProperty:ALAssetsGroupPropertyURL] isEqual:URL];
    }];
    
    return [self.groups indexOfObject:[self.groups filteredArrayUsingPredicate:predicate].firstObject];
}

- (void)updateAssetsGroupForURL:(NSURL *)URL
{
    ALAssetsLibraryGroupResultBlock resultBlock = ^(ALAssetsGroup *group){
        
        NSUInteger index = [self.groups indexOfObject:group];
        
        if (index != NSNotFound)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            [self.groups replaceObjectAtIndex:index withObject:group];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    };
    
    [self.picker.assetsLibrary groupForURL:URL resultBlock:resultBlock failureBlock:nil];
}

- (void)insertAssetsGroupForURL:(NSURL *)URL
{
    ALAssetsLibraryGroupResultBlock resultBlock = ^(ALAssetsGroup *group){
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.groups.count inSection:0];
        
        [self.tableView beginUpdates];
        
        [self.groups addObject:group];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    };
    
    [self.picker.assetsLibrary groupForURL:URL resultBlock:resultBlock failureBlock:nil];
}

- (void)deleteAssetsGroupForURL:(NSURL *)URL
{
    NSUInteger index = [self indexOfAssetsGroupWithURL:URL];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self.tableView beginUpdates];
    
    [self.groups removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
}


#pragma mark - Selected Assets Changed

- (void)selectedAssetsChanged:(NSNotification *)notification
{
    NSArray *selectedAssets = (NSArray *)notification.object;
    
    [[self.toolbarItems objectAtIndex:1] setTitle:[self.picker toolbarTitle]];
    
    [self.picker setToolbarHidden:(selectedAssets.count == 0) animated:YES];
}


#pragma mark - Reload Data

- (void)reloadData
{
    if (self.groups.count > 0)
        [self.tableView reloadData];
    else
        [self showNoAssets];
}


#pragma mark - Not allowed / No assets

- (void)showNotAllowed
{
    self.title = nil;
    self.tableView.backgroundView = [self.picker notAllowedView];
}

- (void)showNoAssets
{
    self.tableView.backgroundView = [self.picker noAssetsView];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CTAssetsGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[CTAssetsGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    [cell bind:[self.groups objectAtIndex:indexPath.row]];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsViewController *vc = [[CTAssetsViewController alloc] init];
    vc.assetsGroup = [self.groups objectAtIndex:indexPath.row];
    
    [self.picker pushViewController:vc animated:YES];
}

@end
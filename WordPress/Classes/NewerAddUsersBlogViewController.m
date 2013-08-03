//
//  NewerAddUsersBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewerAddUsersBlogViewController.h"
#import "AddUsersBlogCell.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"

@interface NewerAddUsersBlogViewController () <UITableViewDataSource, UITableViewDelegate> {
    UIView *_mainTextureView;
    NSMutableArray *_selectedBlogs;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet WPNUXSecondaryButton *selectAll;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *addSelected;


@end

@implementation NewerAddUsersBlogViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.titleLabel.text = NSLocalizedString(@"Select the sites you want to add", nil);
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:29.0];
    
    [self.selectAll setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
    [self.addSelected setTitle:NSLocalizedString(@"Add Selected", nil) forState:UIControlStateNormal];
        
    [self addTextureView];
    
    [self.tableView registerClass:[AddUsersBlogCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)addTextureView
{
    _mainTextureView = [[UIView alloc] initWithFrame:self.view.bounds];
    _mainTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    [self.view addSubview:_mainTextureView];
    [self.view sendSubviewToBack:_mainTextureView];
    _mainTextureView.userInteractionEnabled = NO;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_mainTextureView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mainTextureView]|" options:0 metrics:0 views:views];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mainTextureView]|" options:0 metrics:0 views:views];
    
    [self.view addConstraints:horizontalConstraints];
    [self.view addConstraints:verticalConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
//    return [_usersBlogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    AddUsersBlogCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.showTopSeparator = indexPath.row == 0;
    cell.title = [NSString stringWithFormat:@"Row %d", indexPath.row];
    
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return [AddUsersBlogCell rowHeightWithText:[self getCellTitleForIndexPath:indexPath]];
//}



@end

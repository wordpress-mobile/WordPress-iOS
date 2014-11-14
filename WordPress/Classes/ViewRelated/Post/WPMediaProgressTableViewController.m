//
//  WPMediaProgressTableViewController.m
//  WordPress
//
//  Created by Sergio Estevao on 14/11/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPMediaProgressTableViewController.h"
#import "WPProgressTableViewCell.h"

static NSString * const WPProgressCellIdentifier = @"WPProgressCellIdentifier";

@interface WPMediaProgressTableViewController ()

@property (nonatomic, strong) NSProgress * masterProgress;
@property (nonatomic, strong) NSArray * childrenProgress;

@end

@implementation WPMediaProgressTableViewController

- (instancetype)initWithMasterProgress:(NSProgress *)masterProgress
             childrenProgress:(NSArray *)childrenProgress
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _masterProgress = masterProgress;
        _childrenProgress = childrenProgress;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (IS_IPHONE) {
        // Remove one-pixel gap resulting from a top-aligned grouped table view
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
        
        // Cancel button
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonTapped:)];
        
        self.navigationItem.leftBarButtonItem = cancelButtonItem;
    }
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.tableView registerClass:[WPProgressTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPProgressTableViewCell class])];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.childrenProgress.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WPProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WPProgressTableViewCell class]) forIndexPath:indexPath];
    
    // Configure the cell...
    [cell setProgress:self.childrenProgress[indexPath.row]];
    [WPStyleGuide configureTableViewCell:cell];
    
    return cell;
}

#pragma mark - Actions

- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

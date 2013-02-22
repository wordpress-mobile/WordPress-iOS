//
//  JetpackAuthViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 2/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>

#import "JetpackAuthViewController.h"
#import "Blog+Jetpack.h"
#import "UITableViewTextFieldCell.h"
#import "UIColor+Helpers.h"

@interface JetpackAuthViewController () <UITableViewTextFieldCellDelegate>

@end

@implementation JetpackAuthViewController {
    Blog *_blog;
    NSString *_jetpackVersion;
    UITableViewTextFieldCell *_usernameCell;
    UITableViewTextFieldCell *_passwordCell;
}

- (id)initWithBlog:(Blog *)blog {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _jetpackVersion = blog.jetpackVersion;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 260)];
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 37)];
    headerImageView.image = [UIImage imageNamed:@"clouds_header"];
    headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    [headerView addSubview:headerImageView];

    CGRect jpRect = CGRectMake(0, 40, 320, 100);
    jpRect = CGRectInset(jpRect, 15, 0);
    UIImageView *jpConnectImageView = [[UIImageView alloc] initWithFrame:jpRect];
    jpConnectImageView.image = [UIImage imageNamed:@"logo_jetpack"];
    jpConnectImageView.contentMode = UIViewContentModeScaleAspectFit;
    [headerView addSubview:jpConnectImageView];

    UITextView *connectTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 140, 320, 120)];
    connectTextView.text = NSLocalizedString(@"Looks like you have Jetpack set up on your blog. Congrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", @"");
    connectTextView.font = [UIFont systemFontOfSize:16.f];
    connectTextView.backgroundColor = [UIColor clearColor];
    connectTextView.textAlignment = UITextAlignmentCenter;
    connectTextView.scrollEnabled = NO;
    connectTextView.editable = NO;
    [headerView addSubview:connectTextView];

    self.tableView.tableHeaderView = headerView;

    UIImageView *footerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 32)];
    footerImageView.image = [UIImage imageNamed:@"clouds_footer"];
    footerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.tableView.tableFooterView = footerImageView;

    self.title = NSLocalizedString(@"Jetpack Connect", @"");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(skip:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleDone target:self action:@selector(save:)];

    self.tableView.backgroundColor = [UIColor UIColorFromHex:0xF9F9F9];
    self.tableView.backgroundView = nil;
}

- (void)skip:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)save:(id)sender {
    [SVProgressHUD show];
    NSString *username = _usernameCell.textField.text;
    NSString *password = _passwordCell.textField.text;
    [_blog validateJetpackUsername:username
                          password:password
                           success:^{
                               [SVProgressHUD dismiss];
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
                           } failure:^(NSError *error) {
                               [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                           }];
}

- (void)updateSaveButton {
    if (_usernameCell.textField.text.length && _passwordCell.textField.text.length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)cellWantsToSelectNextField:(UITableViewTextFieldCell *)cell {
    [_passwordCell.textField becomeFirstResponder];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)cellTextDidChange:(UITableViewTextFieldCell *)cell {
    [self updateSaveButton];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewTextFieldCell *cell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Username:", @"");
        cell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
        cell.shouldDismissOnReturn = NO;
        cell.delegate = self;
        _usernameCell = cell;
    } else {
        cell.textLabel.text = NSLocalizedString(@"Password:", @"");
        cell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
        cell.textField.secureTextEntry = YES;
        cell.shouldDismissOnReturn = YES;
        cell.delegate = self;
        _passwordCell = cell;
    }
    
    return cell;
}

@end

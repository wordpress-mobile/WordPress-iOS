//
//  ManageBlogsViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 27/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ManageBlogsViewController.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"

static NSString * const CellIdentifier = @"ManageBlogsCell";

@implementation ManageBlogsViewController {
    WPAccount *_account;
    NSArray *_blogs;
    UIActivityIndicatorView *_activityIndicator;
}

- (id)initWithAccount:(WPAccount *)account {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _account = account;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Visible Blogs", nil);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.tableView.tableFooterView = _activityIndicator;

    [self buildToolbar];
    [self updateBlogs];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refreshBlogs];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)buildToolbar {
    UIBarButtonItem *showAll = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Show All", @"Show all blogs (Manage Blogs)") style:UIBarButtonItemStyleBordered target:self action:@selector(showAll:)];
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *hideAll = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Hide All", @"Hide all blogs (Manage Blogs)") style:UIBarButtonItemStyleBordered target:self action:@selector(hideAll:)];
    [self setToolbarItems:@[showAll, separator, hideAll]];
}

- (void)updateBlogs {
    _blogs = [[_account.blogs allObjects] sortedArrayUsingSelector:@selector(blogName)];
    if ([_blogs count] > 2) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    } else {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)refreshBlogs {
    [_activityIndicator startAnimating];
    [_account syncBlogsWithSuccess:^{
        [self updateBlogs];
        [self.tableView reloadData];
        [_activityIndicator stopAnimating];
    } failure:^(NSError *error) {
        [_activityIndicator stopAnimating];
    }];
}

- (void)setAllBlogsVisible:(BOOL)visible {
    [_blogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Blog *blog = (Blog *)obj;
        blog.visible = visible;
    }];
    [_account.managedObjectContext save:nil];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_blogs count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Visible Blogs", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Blog *blog = [_blogs objectAtIndex:indexPath.row];
    [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:YES];
    cell.textLabel.text = blog.blogName;
    UISwitch *visibilitySwitch = [UISwitch new];
    visibilitySwitch.on = blog.visible;
    visibilitySwitch.tag = indexPath.row;
    [visibilitySwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = visibilitySwitch;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UISwitch *switcher = (UISwitch *)cell.accessoryView;
    if ([switcher isKindOfClass:[UISwitch class]]) {
        [switcher setOn:!switcher.on animated:YES];
        [self switchChanged:switcher];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)switchChanged:(id)sender {
    UISwitch *switcher = (UISwitch *)sender;
    Blog *blog = [_blogs objectAtIndex:switcher.tag];
    blog.visible = switcher.on;
    [blog dataSave];
}

- (void)showAll:(id)sender {
    [self setAllBlogsVisible:YES];
}

- (void)hideAll:(id)sender {
    [self setAllBlogsVisible:NO];
}

@end

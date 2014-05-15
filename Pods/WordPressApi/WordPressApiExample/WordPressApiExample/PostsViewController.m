//
//  PostsViewController.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 12/20/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import "PostsViewController.h"
#import "PostViewController.h"
#import "WordPressApi.h"

@interface PostsViewController ()
@property (readwrite, nonatomic, retain) id<WordPressBaseApi> api;
@property (readwrite, nonatomic, retain) NSArray *posts;
- (void)setupApi;
@end

@implementation PostsViewController
@synthesize api = _api;
@synthesize posts = _posts;

- (void)awakeFromNib
{
    [self setupApi];
    self.posts = [NSArray array];
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.navigationItem.rightBarButtonItems && [self.navigationItem.rightBarButtonItems count] == 1) {
        UIBarButtonItem *logout = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout:)];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, logout, nil];
    }
	// Do any additional setup after loading the view, typically from a nib.
    [self refreshPosts:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"wp_xmlrpc" options:0 context:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear");
    [self setupApi];
    if (self.api == nil) {
        [self.navigationController performSegueWithIdentifier:@"login" sender:self];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];    
    NSDictionary *post = [self.posts objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [post objectForKey:@"title"];
    cell.detailTextLabel.text = [post objectForKey:@"description"];
    return cell;
}

#pragma mark - Table delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showPost" sender:self];
}

#pragma mark - Storyboards

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPost"]) {
        NSDictionary *post = [self.posts objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        PostViewController *postViewController = (PostViewController *)segue.destinationViewController;
        postViewController.post = post;
    }
}

#pragma mark - Custom methods

- (IBAction)refreshPosts:(id)sender {
    [self.api getPosts:10 success:^(NSArray *posts) {
        self.posts = posts;
        NSLog(@"We have %lu posts", (unsigned long)[self.posts count]);
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"Error fetching posts: %@", [error localizedDescription]);
    }];
}

- (void)publishPostWithTitle:(NSString *)title content:(NSString *)content image:(UIImage *)image {
    [self.api publishPostWithImage:image description:content title:title success:^(NSUInteger postId, NSURL *permalink) {
        [self refreshPosts:self];
    } failure:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error posting"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
    }];
}

#pragma mark - Private

- (void)setupApi {
    if (self.api == nil) {
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString *token = [def objectForKey:@"wp_token"];
        NSString *siteId = [def objectForKey:@"wp_site_id"];
        if (token && siteId) {
            self.api = [WordPressApi apiWithOauthToken:token siteId:siteId];
        } else {
            NSString *xmlrpc = [def objectForKey:@"wp_xmlrpc"];
            if (xmlrpc) {
                NSString *username = [def objectForKey:@"wp_username"];
                NSString *password = [def objectForKey:@"wp_password"];
                if (username && password) {
                    self.api = [WordPressApi apiWithXMLRPCURL:[NSURL URLWithString:xmlrpc] username:username password:password];
                }
            }
        }
    }
    if (self.api) {
        [self refreshPosts:self];
    }
}

- (IBAction)logout:(id)sender {
    self.api = nil;
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def removeObjectForKey:@"wp_xmlrpc"];
    [def synchronize];
    [self.navigationController performSegueWithIdentifier:@"login" sender:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"wp_xmlrpc"]) {
        [self setupApi];
    }
}

@end

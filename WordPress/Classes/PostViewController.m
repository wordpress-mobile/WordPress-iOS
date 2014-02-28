//
//  PostViewController.m
//  WordPress
//
//  Created by Eric Johnson on 2/25/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostViewController.h"
#import "AbstractPost.h"
#import "PostContentView.h"
#import "WPActivityDefaults.h"
#import "WPTableViewCell.h"

@interface PostViewController ()<UIScrollViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) PostContentView *postView;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) UIPopoverController *popover;
@end

@implementation PostViewController

- (id)initWithPost:(AbstractPost *)post {
    self = [super init];
    if (self) {
        self.post = post;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.post.postTitle;
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat x = 0.0f;
    UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (IS_IPAD) {
        x = (width - WPTableViewFixedWidth) / 2.0f;
        width = WPTableViewFixedWidth;
        mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    }
    CGRect frame = CGRectMake(x, 0.0f, width, CGRectGetHeight(self.view.bounds));
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.autoresizingMask = mask;
    [self.view addSubview:self.scrollView];
    
    self.postView = [[PostContentView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, CGRectGetHeight(self.view.bounds)) showFullContent:YES];
    self.postView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.postView configurePost:self.post withWidth:width];
    [self.scrollView addSubview:self.postView];
    
    self.navigationItem.rightBarButtonItem = self.shareButton;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateScrollHeight];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self updateScrollHeight];
}

- (void)updateScrollHeight {

    [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.postView.frame), CGRectGetHeight(self.postView.frame))];
}

- (UIBarButtonItem *)shareButton {
    if (_shareButton)
        return _shareButton;
    
	// Top Navigation bar and Sharing
    UIImage *image = [UIImage imageNamed:@"icon-posts-share"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handleShareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _shareButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return _shareButton;
}

- (void)handleShareButtonTapped:(id)sender {
    NSString *permaLink = self.post.permaLink;
    NSString *title = self.post.postTitle;
    
    NSMutableArray *activityItems = [NSMutableArray array];
    if (title) {
        [activityItems addObject:title];
    }
    
    [activityItems addObject:[NSURL URLWithString:permaLink]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[WPActivityDefaults defaultActivities]];
    if (title) {
        [activityViewController setValue:title forKey:@"subject"];
    }
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (!completed)
            return;
        [WPActivityDefaults trackActivityType:activityType withPrefix:@"ReaderDetail"];
    };
    if (IS_IPAD) {
        if (self.popover) {
            [self dismissPopover];
            return;
        }
        self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)dismissPopover {
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}


@end

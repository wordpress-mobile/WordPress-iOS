//
//  ReaderReblogFormView.m
//  WordPress
//
//  Created by Eric J on 6/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderReblogFormView.h"
#import "WordPressComApi.h"
#import "WPToast.h"
#import "NSString+XMLExtensions.h"
#import "ReaderUsersBlogsViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "NSString+Helpers.h"
#import "IOS7CorrectedTextView.h"

@interface ReaderReblogFormView()<ReaderUsersBlogsDelegate>

@property (nonatomic, strong) NSString *siteTitle;
@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) UIButton *blogButton;
@property (nonatomic, strong) UILabel *blogNameLabel;
@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, assign) BOOL blogsAvailable;
@property (nonatomic, strong) UIView *loadingBlogsView;

- (void)handleBlogButtonTapped:(id)sender;

@end

@implementation ReaderReblogFormView

+ (CGFloat)desiredHeight {
	
	UIFont *font = [UIFont systemFontOfSize:ReaderTextFormFontSize];
	CGFloat maxHeight = ReaderTextFormMaxLines * font.lineHeight;
	CGFloat minHeight = ReaderTextFormMinLines * font.lineHeight;
	
	CGFloat height = (IS_IPAD) ? maxHeight : minHeight;
	
	NSArray *blogs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"wpcom_users_blogs"];
	if ([blogs count] > 1) {
		height += 30.0f;
	}
	
	return height + 30.0f; // 15px padding above and below the the UITextView;
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide littleEddieGrey];
		self.requireText = NO;
		self.promptLabel.text = NSLocalizedString(@"Add your thoughts here... (optional)", @"Placeholder text prompting the user to add a note to the post they are reblogging.");
		
        NSArray *blogs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"wpcom_users_blogs"];
        _blogsAvailable = blogs && blogs.count > 0;
        [self setupReblogDestinations:blogs];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
    }
	
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupReblogDestinations:(NSArray *)blogs {
    __block CGRect frame = CGRectZero;
    __block CGFloat offset = 0;
    
    if (blogs.count > 1) {
        frame = CGRectMake(10.0f, 8.0, self.bounds.size.width - 20.0f, 20.0f);
        self.blogButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _blogButton.frame = frame;
        _blogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_blogButton addTarget:self action:@selector(handleBlogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
        buttonView.backgroundColor = [UIColor clearColor];
        buttonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        buttonView.userInteractionEnabled = NO;
        
        NSString *str = NSLocalizedString(@"Post to", @"Lable for the blog selector. Says 'Post to' followed by the blog's icon and its name.");
        UIFont *font = [UIFont fontWithName:@"OpenSans" size:15.0f];
        CGSize size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
        UILabel *postToLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0, size.width, frame.size.height)];
        postToLabel.text = str;
        postToLabel.font = font;
        postToLabel.textColor = [UIColor whiteColor];
        postToLabel.backgroundColor = [UIColor clearColor];
        [buttonView addSubview:postToLabel];
        
        self.blavatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width + 5.0f, 0.0f, 20.0f, 20.0f)];
        _blavatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [buttonView addSubview:_blavatarImageView];
        
        CGFloat x = _blavatarImageView.frame.origin.x + 25.0f;
        self.blogNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0.0f, frame.size.width - x, frame.size.height)];
        _blogNameLabel.backgroundColor = [UIColor clearColor];
        _blogNameLabel.font = font;
        _blogNameLabel.textColor = [UIColor whiteColor];
        _blogNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [buttonView addSubview:_blogNameLabel];
        
        [_blogButton addSubview:buttonView];
        [self addSubview:_blogButton];
        
        offset = CGRectGetMaxY(_blogButton.frame);
        
        NSNumber *primaryBlogId = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_users_prefered_blog_id"];
        if (primaryBlogId) {
            [blogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([[obj numberForKey:@"blogid"] isEqualToNumber:primaryBlogId]) {
                    [self configureDestinationBlogFromDictionary:obj];
                    *stop = YES;
                }
            }];
        } else {
            [self configureDestinationBlogFromDictionary:[blogs objectAtIndex:0]];
        }
    } else if ([blogs count]) {
        offset = -CGRectGetMaxY(_loadingBlogsView.frame);
        [self configureDestinationBlogFromDictionary:[blogs objectAtIndex:0]];
    } else {
        // No blogs yet, they're probably being loaded
        _loadingBlogsView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 8.0f, self.bounds.size.width, 20.0f)];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.frame = CGRectMake(0, 0, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
        [activityIndicator startAnimating];
        [_loadingBlogsView addSubview:activityIndicator];
        
        UILabel *noBlogsLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(activityIndicator.frame) + 10.0f, 0, _loadingBlogsView.bounds.size.width - CGRectGetMaxX(activityIndicator.frame), _loadingBlogsView.frame.size.height)];
        noBlogsLabel.text = NSLocalizedString(@"Loading sites...", @"");
        noBlogsLabel.backgroundColor = [UIColor clearColor];
        noBlogsLabel.textColor = [UIColor whiteColor];
        noBlogsLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0f];
        [_loadingBlogsView addSubview:noBlogsLabel];

        [self addSubview:_loadingBlogsView];
        
        offset = CGRectGetMaxY(_loadingBlogsView.frame);
    }
    
    if (!(_loadingBlogsView && blogs.count > 1)) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            frame = self.borderImageView.frame;
            frame.origin.y += offset;
            frame.size.height -= offset;
            self.borderImageView.frame = frame;
            
            frame = self.textView.frame;
            frame.origin.y += offset;
            frame.size.height -= offset;
            self.textView.frame = frame;
            
            frame = self.promptLabel.frame;
            frame.origin.y += offset;
            self.promptLabel.frame = frame;
            
            frame = self.activityView.frame;
            frame.origin.y = ((self.textView.frame.origin.y + (self.textView.frame.size.height / 2.0f)) - frame.size.height / 2.0f) ;
            self.activityView.frame = frame;
        } completion:nil];
    }
    
    if (blogs) {
        [_loadingBlogsView removeFromSuperview];
        _loadingBlogsView = nil;
    }
    
    self.sendButton.enabled = [self shouldEnableSendButton];
}

- (void)handleSendButtonTapped:(id)sender {
	[super handleSendButtonTapped:sender];
	
	[self enableForm:NO];
	[self.activityView startAnimating];

	[self.post reblogPostToSite:_siteId note:[[self text] trim] success:^{
		
		[WPToast showToastWithMessage:NSLocalizedString(@"Reblogged", @"User reblogged a post.")
							 andImage:[UIImage imageNamed:@"action_icon_replied"]];
		
		[self enableForm:YES];
		[self.activityView stopAnimating];
		[self setText:@""];
		
		if ([self.delegate respondsToSelector:@selector(readerTextFormDidSend:)]) {
			[self.delegate readerTextFormDidSend:self];
		}
        
        [WPMobileStats trackEventForWPCom:StatsEventReaderReblogged];
		
	} failure:^(NSError *error) {
		DDLogError(@"Error Reblogging Post : %@", [error localizedDescription]);
		[self enableForm:YES];
		[self.activityView stopAnimating];
		[self.textView becomeFirstResponder];

		// TODO: Failure reason.
        [WPError showAlertWithTitle:NSLocalizedString(@"Reblog failed", nil) message:NSLocalizedString(@"There was a problem reblogging. Please try again.", nil)];
	}];

}


- (void)handleBlogButtonTapped:(id)sender {    
    ReaderUsersBlogsViewController *controller = [[ReaderUsersBlogsViewController alloc] init];
	controller.delegate = self;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
	navController.modalPresentationStyle = UIModalPresentationFormSheet;
    if (!IS_IPAD) {
        // Avoid a weird issue on the iPad with cross dissolves when the keyboard is visible.
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    [[[WordPressAppDelegate sharedWordPressApplicationDelegate].window rootViewController] presentViewController:navController animated:YES completion:nil];
}


- (void)configureNavItem {
	[super configureNavItem];

	self.titleLabel.text = NSLocalizedString(@"Reblogging", @"");
	self.detailLabel.text = self.post.postTitle;
	[self.sendButton setTitle:NSLocalizedString(@"Reblog", nil)];
}

- (BOOL)shouldEnableSendButton {
    BOOL shouldEnable = [super shouldEnableSendButton];
    return shouldEnable && _blogsAvailable;
}

- (void)userDefaultsChanged {
    NSArray *blogs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"wpcom_users_blogs"];
    if (!_blogsAvailable && blogs != nil && blogs.count > 0) {
        _blogsAvailable = YES;
        [self setupReblogDestinations:blogs];
    }
}

- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post]) {
		return;
	}
	
	_post = post;
	[self setText:@""];
	[self updateNavItem];
}

- (void)configureDestinationBlogWithID:(NSNumber *)blogID name:(NSString *)blogName url:(NSString *)urlString {
	self.siteId = blogID;
	self.siteTitle = blogName;
    
    if (_blogButton) {
		NSURL *url = [NSURL URLWithString:urlString];
		[_blavatarImageView setImageWithBlavatarUrl:[url host] isWPcom:YES];
		_blogNameLabel.text = _siteTitle;
	}
    
	[self updateNavItem];
}

- (void)configureDestinationBlog:(Blog *)blog {
    [self configureDestinationBlogWithID:blog.blogID name:blog.blogName url:blog.url];
}

- (void)configureDestinationBlogFromDictionary:(NSDictionary *)dict {
    NSNumber *siteId = [dict numberForKey:@"blogid"];
	NSString *siteTitle = [dict stringForKey:@"blogName"];
    NSString *url = [dict stringForKey:@"url"];
    
    [self configureDestinationBlogWithID:siteId name:siteTitle url:url];
}


#pragma mark - ReaderUsersBlog Delegate method

- (void)userDidSelectBlog:(Blog *)blog {
	[self configureDestinationBlog:blog];
}


@end

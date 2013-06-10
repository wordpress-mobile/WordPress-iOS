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
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "ReaderUsersBlogsViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "NSString+Helpers.h"

@interface ReaderReblogFormView()<ReaderUsersBlogsDelegate>

@property (nonatomic, strong) NSString *siteTitle;
@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) UIButton *blogButton;
@property (nonatomic, strong) UILabel *blogNameLabel;
@property (nonatomic, strong) UIImageView *blavatarImageView;

- (void)setDestinationBlog:(NSDictionary *)dict;
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
		height += 40.0f;
	}
	
	return height + 30.0f; // 15px padding above and below the the UITextView;
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.promptLabel.text = NSLocalizedString(@"Add your thoughts here... (optional)", @"Placeholder text prompting the user to add a note to the post they are reblogging.");
		
		frame = CGRectMake(10.0f, 10.0, frame.size.width - 20.0f, 30.0f);
		
		NSArray *blogs = [[NSUserDefaults standardUserDefaults] arrayForKey:@"wpcom_users_blogs"];
		if ([blogs count] > 1) {
		
			self.blogButton = [UIButton buttonWithType:UIButtonTypeCustom];
			_blogButton.frame = frame;
			_blogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			[_blogButton addTarget:self action:@selector(handleBlogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

			UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
			buttonView.backgroundColor = [UIColor clearColor];
			buttonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			buttonView.userInteractionEnabled = NO;
			
			self.blogNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(35.0f, 0.0f, frame.size.width - 35.0f, frame.size.height)];
			_blogNameLabel.backgroundColor = [UIColor clearColor];
			_blogNameLabel.font = [UIFont systemFontOfSize:14.0f];
			_blogNameLabel.textColor = [UIColor whiteColor];
			_blogNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			[buttonView addSubview:_blogNameLabel];
			
			self.blavatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
			_blavatarImageView.contentMode = UIViewContentModeScaleAspectFit;
			[buttonView addSubview:_blavatarImageView];

			[_blogButton addSubview:buttonView];
			[self addSubview:_blogButton];
			
			CGFloat offset = _blogButton.frame.origin.y + _blogButton.frame.size.height;
			
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

			NSNumber *primaryBlogId = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_users_prefered_blog_id"];
			[blogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([[obj numberForKey:@"blogid"] isEqualToNumber:primaryBlogId]) {
					[self setDestinationBlog:obj];
					stop = YES;
				}
			}];
		} else {
			[self setDestinationBlog:[blogs objectAtIndex:0]];
		}
    }
	
    return self;
}


- (void)didMoveToWindow {
	
}


- (void)handleSendButtonTapped:(id)sender {
	[super handleSendButtonTapped:sender];
	
	self.textView.editable = NO;
	self.sendButton.enabled = NO;
	[self.activityView startAnimating];
	
	[self.post reblogPostToSite:_siteId note:[[self text] trim] success:^{
		[WPToast showToastWithMessage:NSLocalizedString(@"Replied", @"User replied to a comment")
							 andImage:[UIImage imageNamed:@"action_icon_replied"]];
	} failure:^(NSError *error) {
		self.sendButton.enabled = YES;
		self.textView.editable = YES;
		[self.activityView stopAnimating];
		// TODO: Failure reason.
	}];

}


- (void)handleBlogButtonTapped:(id)sender {
	[ReaderUsersBlogsViewController presentAsModalWithDelegate:self];
}


- (void)configureNavItem {
	[super configureNavItem];

	self.titleLabel.text = NSLocalizedString(@"Reblogging", @"");
	self.detailLabel.text = self.post.postTitle;
	[self.sendButton setTitle:NSLocalizedString(@"Reblog", nil)];
}


- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post]) {
		return;
	}
	
	_post = post;
	[self updateNavItem];
}


- (void)setDestinationBlog:(NSDictionary *)dict {
	
	self.siteId = [dict numberForKey:@"blogid"];
	self.siteTitle = [dict stringForKey:@"blogName"];

	if (_blogButton) {
		NSURL *url = [NSURL URLWithString:[dict stringForKey:@"url"]];
		[_blavatarImageView setImageWithBlavatarUrl:[url host] isWPcom:YES];
		_blogNameLabel.text = _siteTitle;
	}

	[self updateNavItem];
}


#pragma mark - ReaderUsersBlog Delegate method

- (void)userDidSelectBlog:(NSDictionary *)blog {
	[self setDestinationBlog:blog];
}


@end

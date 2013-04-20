//
//  ReaderPostDetailViewController.m
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostDetailViewController.h"
#import "UIImageView+Gravatar.h"
#import <DTCoreText/DTCoreText.h>

@interface ReaderPostDetailViewController ()

@property (nonatomic, strong) DTAttributedTextContentView *textContentView;

@end

@implementation ReaderPostDetailViewController

@synthesize post;


#pragma mark - LifeCycle Methods

- (void)dealloc {
	
}


- (id)initWithPost:(ReaderPost *)apost {
	self = [super initWithNibName:nil bundle:nil];
	if(self) {
		self.post = apost;
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super initWithNibName:nil bundle:nil];
	if(self) {
		// TODO: for supporting Twitter cards.
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = self.post.postTitle;
	self.titleLabel.text = [self.post.blogName stringByReplacingHTMLEntities];
	[self.blavatarImageView setImageWithBlavatarUrl:[self.post blogURL]];
	
	
	self.textContentView = [[DTAttributedTextContentView alloc] initWithAttributedString:nil width:self.view.frame.size.width];
	_textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textContentView.backgroundColor = [UIColor clearColor];
	_textContentView.edgeInsets = UIEdgeInsetsMake(0.f, 10.f, 0.f, 10.f);
	_textContentView.shouldDrawImages = YES;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
														  DTDefaultFontFamily: @"Helvetica",
										   NSTextSizeMultiplierDocumentOption: [NSNumber numberWithFloat:1.3]
								 }];
	_textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:[post.content dataUsingEncoding:NSUTF8StringEncoding] options:dict documentAttributes:NULL];
	
	CGFloat height = [_textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:self.view.frame.size.width].height;
	
	_textContentView.frame = CGRectMake(0.0f, 44.0f, self.view.frame.size.width, height);
	[self.contentView addSubview:_textContentView];
	
	CGRect frame = self.contentView.frame;
	frame.size.width = self.view.frame.size.width;
	frame.size.height = 64.0f + height;
	self.contentView.frame = frame;
	
	[self.scrollView setContentSize:self.contentView.frame.size];

}


#pragma mark - Instance Methods

- (IBAction)handleLikeButtonTapped:(id)sender {
	
}


- (IBAction)handleFollowButtonTapped:(id)sender {
	
}


- (IBAction)handleReblogButtonTapped:(id)sender {
	
}


- (IBAction)handleActionButtonTapped:(id)sender {
	
}



@end

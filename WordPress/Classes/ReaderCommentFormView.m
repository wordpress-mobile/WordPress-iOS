//
//  ReaderCommentFormView.m
//  WordPress
//
//  Created by Eric J on 6/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderCommentFormView.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "WPToast.h"
#import "iOS7CorrectedTextView.h"

@implementation ReaderCommentFormView

+ (CGFloat)desiredHeight {

	UIFont *font = [UIFont systemFontOfSize:ReaderTextFormFontSize];
	CGFloat maxHeight = ReaderTextFormMaxLines * font.lineHeight;
	CGFloat minHeight = ReaderTextFormMinLines * font.lineHeight;

	CGFloat height = (IS_IPAD) ? maxHeight : minHeight;
	
	return height + 30.0f; // 15px padding above and below the the UITextView;
}


- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.promptLabel.text = NSLocalizedString(@"Tap to type a comment", @"Placeholder for a text field, prompting the user to tap the field to begin typing their comment.");
	}
	return self;
}


- (void)handleSendButtonTapped:(id)sender {
	[super handleSendButtonTapped:sender];
	
	NSString *str = [[self text] trim];
	if ([str length] == 0) {
		return;
	}
	
	[self enableForm:NO];
	[self.activityView startAnimating];

	NSString *path;
	if (self.comment != nil) {
		path = [NSString stringWithFormat:@"sites/%@/comments/%@/replies/new", self.post.siteID, self.comment.commentID];
	} else {
		path = [NSString stringWithFormat:@"sites/%@/posts/%@/replies/new", self.post.siteID, self.post.postID];
	}
	
	NSDictionary *params = @{@"content":str};
	[[WordPressComApi sharedApi] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		NSDictionary *params = @{@"number":@100};
		
		[ReaderPost getCommentsForPost:[self.post.postID integerValue]
							  fromSite:[self.post.siteID stringValue]
						withParameters:params
							   success:^(AFHTTPRequestOperation *operation, id responseObject) {
								   self.textView.editable = YES;
								   self.promptLabel.hidden = NO;
								   [self setText:nil];
								   [self.activityView stopAnimating];
								   self.post.dateCommentsSynced = [NSDate date];
								   
								   [WPToast showToastWithMessage:NSLocalizedString(@"Replied", @"User replied to a comment")
														andImage:[UIImage imageNamed:@"action_icon_replied"]];
								   
								   NSDictionary *resp = (NSDictionary *)responseObject;
								   NSArray *commentsArr = [resp objectForKey:@"comments"];
								   
								   [ReaderComment syncAndThreadComments:commentsArr
																forPost:self.post
															withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
								   
								   if([self.delegate respondsToSelector:@selector(readerTextFormDidSend:)]) {
									   [self.delegate readerTextFormDidSend:self];
								   }
                                   
                                   [WPMobileStats trackEventForWPCom:StatsEventReaderPublishedComment];
                                   [WPMobileStats pingWPComStatsEndpoint:@"publish_comment"];
							   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								   [self enableForm:YES];
								   [self.activityView stopAnimating];
								   // TODO: Failure reason.
							   }];
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		WPLog(@"Error Commenting from Reader : %@", [error localizedDescription]);
		[self enableForm:YES];
		[self.activityView stopAnimating];
		[self.textView becomeFirstResponder];
		// TODO: Failure reason.
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Comment failed", @"")
															message:NSLocalizedString(@"There was a problem commenting. Please try again.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
												  otherButtonTitles:nil];
		[alertView show];
	}];
}


- (void)configureNavItem {
	[super configureNavItem];
	
	if (_comment) {
		self.titleLabel.text = NSLocalizedString(@"Replying", @"");
		self.detailLabel.text = [NSString stringWithFormat:@"to %@", self.comment.author];
		[self.sendButton setTitle:NSLocalizedString(@"Reply", nil)];
	} else {
		self.titleLabel.text = NSLocalizedString(@"Commenting", @"");
		self.detailLabel.text = [NSString stringWithFormat:@"on %@", self.post.postTitle];
		[self.sendButton setTitle:NSLocalizedString(@"Comment", nil)];
	}
}


- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post]) {
		return;
	}

	_post = post;
	[self updateNavItem];
}


- (void)setComment:(ReaderComment *)comment {
	if ([comment isEqual:_comment]) {
		return;
	}
	
	_comment = comment;
	[self setText:@""];
	[self updateNavItem];
}


@end

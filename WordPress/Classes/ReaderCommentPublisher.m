//
//  ReaderCommentComposer.m
//  WordPress
//

#import "ReaderCommentPublisher.h"
#import "ContextManager.h"
#import "NSString+Util.h"
#import "ReaderPost.h"
#import "ReaderComment.h"
#import "WPToast.h"


@interface ReaderCommentPublisher ()

@property (nonatomic, strong, readwrite) InlineComposeView *composeView;

@end

@implementation ReaderCommentPublisher

- (id)initWithComposer:(InlineComposeView *)composeView andPost:(ReaderPost *)post {
    self = [super init];
    if (self) {
        _composeView = composeView;
        _composeView.delegate = self;

        _post = post;
    }
    return self;
}

- (void)dealloc {
    self.post = nil;
    self.comment = nil;
    self.composeView.delegate = nil;
    self.composeView = nil;
}

#pragma mark - InlineComposeViewDelegate

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text {

    // TODO: Set an activity indicator and disable form
    // TODO: Publish the comment
    [self publishComment:text];

}

#pragma mark - Networking

// Determine the path for the endpoint we're using to post to.
- (NSString *)pathForContext {
	if (self.comment != nil) {
		return [NSString stringWithFormat:@"sites/%@/comments/%@/replies/new", self.post.siteID, self.comment.commentID];
	} else {
		return [NSString stringWithFormat:@"sites/%@/posts/%@/replies/new", self.post.siteID, self.post.postID];
	}
}

// Attempt to publish the comment using the REST API
- (void)publishComment:(NSString *)commentText {

    // check for empty comments, TODO: punt this to the inline composer?
    NSString *str = [commentText trim];
	if ([str length] == 0) {
		return;
	}

	// [self.activityView startAnimating];


	NSDictionary *params = @{@"content":str};

	[[WordPressComApi sharedApi] postPath:[self pathForContext] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        // TODO: build actual comment model
        [self.delegate commentPublisherDidPublishComment:self];

	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        if ([self.delegate respondsToSelector:@selector(commentPublisherDidFailPublishingComment:)]) {
            [self.delegate commentPublisherDidPublishComment:self];
            return;
        }

		DDLogError(@"Error Commenting from Reader : %@", [error localizedDescription]);
		// TODO: Failure reason.
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Comment failed", @"")
															message:NSLocalizedString(@"There was a problem commenting. Please try again.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
												  otherButtonTitles:nil];
		[alertView show];
	}];

}

@end

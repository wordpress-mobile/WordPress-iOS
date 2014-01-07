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
#import "WPAccount.h"


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

#pragma mark - Accessors

- (void)setComment:(ReaderComment *)comment {
    if (_comment == comment) {
        return;
    }

    _comment = comment;

    // if the comment is nil, clear the composer and bail
    if (comment == nil) {
        [self.composeView clearText];
        return;
    }

    // try to restore the comment from the post
    NSDictionary *storedComment = [self.post getStoredComment];

    // if there's no stored comment dismiss it
    if (storedComment == nil){
        [self.composeView clearText];
        return;
    }

    // if the stored comment's comment id matches the comment id use the text
    //  @{@"commentID":commentID, @"comment":commentText};

    NSNumber *commentId = storedComment[ReaderPostStoredCommentIDKey];

    // if the id's do not match, clear the text
    if (![commentId isEqualToNumber:comment.commentID]){
        [self.composeView clearText];
        return;
    }

    self.composeView.text = storedComment[ReaderPostStoredCommentTextKey];

}

- (void)setPost:(ReaderPost *)post {
    if (_post == post) {
        return;
    }

    _post = post;

    // when the post is changed, clear the text
    // we should store not just replies to comments, but posts as well
    [self.composeView clearText];
}

#pragma mark - InlineComposeViewDelegate

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text {

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

    self.composeView.enabled = NO;
	NSDictionary *params = @{@"content":str};

	[[[WPAccount defaultWordPressComAccount] restApi] postPath:[self pathForContext] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        [self.composeView clearText];
        self.composeView.enabled = YES;
        [self.delegate commentPublisherDidPublishComment:self];

        // clear the draft comment for this post if there is one
        self.post.storedComment = nil;

	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {

		DDLogError(@"Error Commenting from Reader : %@", [error localizedDescription]);

        if ([self.delegate respondsToSelector:@selector(commentPublisherDidFailPublishingComment:)]) {
            [self.delegate commentPublisherDidPublishComment:self];
        }

        self.composeView.enabled = YES;

		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Comment failed", @"")
															message:NSLocalizedString(@"There was a problem commenting. Please try again.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
												  otherButtonTitles:nil];
		[alertView show];
	}];

}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
    // if we have a comment, store the draft in the post, yeah, it's weird
    // TODO: support storing draft replies for all comments and the post
    NSString *text = textView.text;

    if ([[text trim] isEqualToString:@""]) {
        return;
    }

    if (self.comment != nil) {
        [self.post storeComment:self.comment.commentID comment:textView.text];
        [self.post save];
    }
}

@end

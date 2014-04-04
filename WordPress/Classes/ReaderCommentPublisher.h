#import <Foundation/Foundation.h>
#include "InlineComposeView.h"

@class ReaderPost, ReaderComment, ReaderCommentPublisher;

@protocol ReaderCommentPublisherDelegate <NSObject>

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)publisher;

@optional

// optional, default is to show a UIAlertView notifying failure
- (void)commentPublisherDidFailPublishingComment:(ReaderCommentPublisher *)publisher;

@end

@interface ReaderCommentPublisher : NSObject <InlineComposeViewDelegate>

@property (nonatomic, weak) id <ReaderCommentPublisherDelegate> delegate;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderComment *comment;
@property (nonatomic, strong, readonly) InlineComposeView *composeView;

- (id)initWithComposer:(InlineComposeView *)composeView andPost:(ReaderPost *)post;

@end

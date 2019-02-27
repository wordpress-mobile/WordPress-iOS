#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * TODO This can be converted to Swift but these tests fail when we do:
 *
 * - ApproveCommentActionTests.testExecuteCallsApproveWhenIconIsOff()
 * - ApproveCommentActionTests.testExecuteCallsUnapproveWhenIconIsOn()
 * - ApproveCommentActionTests.testExecuteUpdatesIconAccessibilityHintWhenIconIsOff()
 * - ApproveCommentActionTests.testExecuteUpdatesIconAccessibilityHintWhenIconIsOn()
 * - ApproveCommentActionTests.testExecuteUpdatesIconAccessibilityLabelWhenIconIsOff()
 * - ApproveCommentActionTests.testExecuteUpdatesIconAccessibilityLabelWhenIconIsOn()
 * - ApproveCommentActionTests.testExecuteUpdatesIconTitleWhenIconIsOff()
 * - ApproveCommentActionTests.testExecuteUpdatesIconTitleWhenIconIsOn()
 * - TrashCommentActionTests.testExecuteCallsTrash()
 */
@interface ReachabilityUtils : NSObject

+ (BOOL)isInternetReachable;

+ (NSString *)noConnectionMessage;

@end

NS_ASSUME_NONNULL_END

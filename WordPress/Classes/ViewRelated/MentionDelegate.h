#import <UIKit/UIKit.h>

@protocol MentionDelegate <NSObject>

@optional
/**
 Tells the delegate the user has typed @ sign. It will NOT work if the user replaces text.
 */
- (void)didStartAtMention:(UIView *)view;

@end
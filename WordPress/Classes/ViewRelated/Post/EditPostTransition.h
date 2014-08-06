#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EditPostTransitionMode){
    EditPostTransitionModePresent = 0,
    EditPostTransitionModeDismiss
};

@interface EditPostTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) EditPostTransitionMode mode;

@end

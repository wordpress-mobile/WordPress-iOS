#import <UIKit/UIKit.h>



typedef void (^UIActionSheetCompletion) (NSString *buttonTitle);

#pragma mark =====================================================================================
#pragma mark UIActionSheet Helpers
#pragma mark =====================================================================================

@interface UIActionSheet (Helpers)

- (instancetype)initWithTitle:(NSString*)title
            cancelButtonTitle:(NSString*)cancelButtonTitle
       destructiveButtonTitle:(NSString*)destructiveButtonTitle
            otherButtonTitles:(NSArray*)otherButtonTitles
                   completion:(UIActionSheetCompletion)completion;

@end

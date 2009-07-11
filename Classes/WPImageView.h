#import <UIKit/UIKit.h>

@interface WPImageView : UIImageView {
    id delegate;
    SEL operation;
}

- (void)setDelegate:(id)aDelegate operation:(SEL)anOperation;

@end

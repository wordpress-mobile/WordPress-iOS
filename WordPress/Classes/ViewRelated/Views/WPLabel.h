#import <UIKit/UIKit.h>


typedef enum {
    VerticalAlignmentTop = 0,
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,
} VerticalAlignment;

@interface WPLabel : UILabel {
@private
    VerticalAlignment verticalAlignment;
}

@property (nonatomic) VerticalAlignment verticalAlignment;

@end

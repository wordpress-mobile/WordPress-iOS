#import "ReaderTextFormView.h"
#import "ReaderPost.h"

@interface ReaderReblogFormView : ReaderTextFormView

@property (nonatomic, strong) ReaderPost *post;

+ (CGFloat)desiredHeight;

@end

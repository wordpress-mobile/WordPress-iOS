#import <Foundation/Foundation.h>

typedef void(^PostCardActionBarItemCallback)();

@interface PostCardActionBarItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) UIEdgeInsets imageInsets;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, copy) PostCardActionBarItemCallback callback;

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)image;

@end

#import "PostCardActionBarItem.h"

@implementation PostCardActionBarItem : NSObject
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    PostCardActionBarItem *item = [PostCardActionBarItem new];
    item.title = title;
    item.image = image;
    item.imageInsets = UIEdgeInsetsZero;
    item.highlightedImage = highlightedImage;
    return item;
}
@end

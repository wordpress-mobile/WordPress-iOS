#import <UIKit/UIKit.h>
#import "PostCategory.h"

@interface WPCategoryTree : NSObject

@property (nonatomic, strong) PostCategory *parent;
@property (nonatomic, strong) NSMutableArray *children;

- (id)initWithParent:(PostCategory *)parent;
- (NSArray *)getAllObjects;
- (void)getChildrenFromObjects:(NSArray *)collection;

@end

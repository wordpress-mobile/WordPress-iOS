//
//  WPCategoryTree.h
//  WordPress
//
//  Created by JanakiRam on 30/01/09.

#import <UIKit/UIKit.h>

@interface WPCategoryTree : NSObject {
    id parent;
    NSMutableArray *children;
}

- (id)initWithParent:(id)aParent;
- (NSArray *)getAllObjects;
- (void)getChildrenFromObjects:(NSArray *)collection;

@end

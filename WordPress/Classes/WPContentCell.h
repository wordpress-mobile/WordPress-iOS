//
//  WPContentCell.h
//  
//
//  Created by Tom Witkin on 12/12/13.
//
//

#import <UIKit/UIKit.h>

#import "WPTableViewCell.h"
#import "WPContentViewProvider.h"

@interface WPContentCell : WPTableViewCell

@property (nonatomic, strong) id<WPContentViewProvider> contentProvider;

+ (CGFloat)rowHeightForContentProvider:(id<WPContentViewProvider>)contentProvider andWidth:(CGFloat)width;

@end

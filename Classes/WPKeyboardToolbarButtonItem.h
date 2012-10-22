//
//  WPKeyboardToolbarButtonItem.h
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPKeyboardToolbarButtonItem : UIButton {
}
+ (id)button;
- (void)setImageName:(NSString *)imageName;
@property (nonatomic, strong) NSString *actionTag, *actionName;
@end

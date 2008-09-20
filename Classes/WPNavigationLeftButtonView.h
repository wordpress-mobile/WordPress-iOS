//
//  WPNavigationLeftButtonView.h
//  WordPress
//
//  Created by Janakiram on 18/09/08.
//  Copyright 2008 Effigent. All rights reserved.

#import <UIKit/UIKit.h>


@interface WPNavigationLeftButtonView : UIView {

    UIButton *addButton;
    UILabel *addLabel;
}

@property (nonatomic, assign) NSString *title;

+ (WPNavigationLeftButtonView *) createView;

-(void)setTarget:(id)aTarget withAction:(SEL)action;

@end




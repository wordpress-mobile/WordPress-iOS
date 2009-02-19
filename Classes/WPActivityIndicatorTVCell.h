//
//  WPActivityIndicatorTVCell.h
//  WordPress
//
//  Created by JanakiRam on 12/02/09.
//  Copyright 2009 Prithvi Information Solutions Limited. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WPActivityIndicatorTVCell : UITableViewCell {

	UIActivityIndicatorView *activityIndicatorView;
}

-(void)startActivityAnimation;
-(void)stopActivityAnimation;
-(void)reset;

@end

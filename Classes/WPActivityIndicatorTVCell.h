//
//  WPActivityIndicatorTVCell.h
//  WordPress
//
//  Created by JanakiRam on 12/02/09.
//

#import <UIKit/UIKit.h>


@interface WPActivityIndicatorTVCell : UITableViewCell {

	UIActivityIndicatorView *activityIndicatorView;
}

-(void)startActivityAnimation;
-(void)stopActivityAnimation;
-(void)reset;

@end

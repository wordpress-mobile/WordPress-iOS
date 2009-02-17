//
//  WPActivityIndicatorTVCell.m
//  WordPress
//
//  Created by JanakiRam on 12/02/09.
//  Copyright 2009 Prithvi Information Solutions Limited. All rights reserved.
//

#import "WPActivityIndicatorTVCell.h"


@implementation WPActivityIndicatorTVCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		CGRect frame = [activityIndicatorView frame];
//		frame.origin.x = [self.contentView bounds].size.width - frame.size.width-60.0;
		frame.origin.x = [self.contentView bounds].size.width - frame.size.width;

		frame.origin.y += 15;
		[activityIndicatorView setFrame:frame];
		activityIndicatorView.tag = 1;	
		activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

		[self.contentView addSubview:activityIndicatorView];
		[self.contentView bringSubviewToFront:activityIndicatorView];
		
		UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(10, 2 , 230, 50)];
		[labelName setBackgroundColor:[UIColor clearColor]];
		labelName.font = [UIFont boldSystemFontOfSize:18.0];
		labelName.tag = (NSInteger)2;
		[self.contentView addSubview:labelName];
		[labelName release];
		
    }
    return self;
}

-(void)startActivityAnimation
{
	[activityIndicatorView startAnimating];
}

-(void)stopActivityAnimation
{
	[activityIndicatorView stopAnimating];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    
	[activityIndicatorView release];
	[super dealloc];
}


@end

//
//  ReaderTableViewCell.m
//  WordPress
//
//  Created by Eric J on 5/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderTableViewCell.h"
#import "WPWebViewController.h"

@implementation ReaderTableViewCell

#pragma mark - Lifecycle Methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

		self.cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)]; // arbitrary size.
		_cellImageView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
		_cellImageView.contentMode = UIViewContentModeScaleAspectFill;
		_cellImageView.clipsToBounds = YES;
		[self.contentView addSubview:_cellImageView];
    }
	
    return self;
}


- (void)prepareForReuse {
	[super prepareForReuse];
	[_cellImageView cancelImageRequestOperation];
	_cellImageView.image = nil;
}


@end

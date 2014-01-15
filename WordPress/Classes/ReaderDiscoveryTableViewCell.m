//
//  ReaderDiscoveryTableViewCell.m
//  WordPress
//
//  Created by aerych on 1/15/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "ReaderDiscoveryTableViewCell.h"
#import "ReaderPostView.h"

@implementation ReaderDiscoveryTableViewCell

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
    // iPhone has extra padding around each cell
    if (IS_IPHONE) {
        width = width - 2 * RPTVCHorizontalOuterPadding;
    }
    
	CGFloat desiredHeight = [ReaderPostView heightWithoutAttributionForPost:post withWidth:width];
    
	return ceil(desiredHeight);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.postView.hidesAttribution = YES;
    }
	
    return self;
}


@end

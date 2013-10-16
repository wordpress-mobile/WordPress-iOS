//
//  UILabel+SuggestSize.m
//  WordPress
//
//  Created by Eric J on 6/18/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UILabel+SuggestSize.h"

@implementation UILabel (SuggestSize)

- (CGSize)suggestedSizeForWidth:(CGFloat)width {
	
	return [self suggestSizeForString:self.text atWidth:width];
	
}


- (CGSize)suggestSizeForString:(NSString *)string atWidth:(CGFloat)width {
	
	return [string sizeWithFont:self.font constrainedToSize:CGSizeMake(width, 9999.0f) lineBreakMode:self.lineBreakMode];

}

@end

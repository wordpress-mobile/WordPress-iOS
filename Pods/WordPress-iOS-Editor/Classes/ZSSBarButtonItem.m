//
//  ZSSBarButtonItem.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 12/3/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import "ZSSBarButtonItem.h"

@implementation ZSSBarButtonItem

- (BOOL)selected
{
	UIButton* button = (UIButton*)self.customView;
	
	return button.selected;
}

- (void)setSelected:(BOOL)selected
{
	UIButton* button = (UIButton*)self.customView;
	
	button.selected = selected;
}

@end

//
//  ZSSBarButtonItem.h
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 12/3/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZSSBarButtonItem : UIBarButtonItem

/**
 *	@brief		The HTML property that matches this bar button.
 *	@details	Whenever the user selects some text, our javascript code returns the list of
 *				properties for the selected text.  Use this property to match against that to know
 *				if the bar button needs to be highlighted.
 */
@property (nonatomic, strong, readwrite) NSString *htmlProperty;

/**
 *	@brief		Use this method to query for the selected state of this bar button.
 *
 *	@returns	YES if selected, NO otherwise.
 */
- (BOOL)selected;

/**
 *	@brief		Use this method to select or deselect this bar button.
 *
 *	@param		selected	Indicated wether the bar button must be selected or deselected.
 */
- (void)setSelected:(BOOL)selected;

@end

//
//  NoteBodyItem.h
//  WordPress
//
//  Created by Jorge Leandro Perez on 3/31/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>



@class NoteAction;

@interface NoteBodyItem : NSObject

@property (nonatomic, readonly) NSString	*headerHtml;
@property (nonatomic, readonly) NSString	*headerText;
@property (nonatomic, readonly) NSString	*headerLink;
@property (nonatomic, readonly) NSString	*bodyHtml;
@property (nonatomic, readonly) NSURL		*iconURL;
@property (nonatomic, readonly) CGSize		iconSize;

@property (nonatomic, readonly) NoteAction	*action;

+ (NSArray *)parseItems:(NSArray *)rawItems;

@end

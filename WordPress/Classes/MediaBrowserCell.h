/*
 * MediaBrowserCell.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import <UIKit/UIKit.h>

@class Media;

@interface MediaBrowserCell : UICollectionViewCell

@property (nonatomic, strong) Media *media;

@end

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

@protocol MediaBrowserCellMultiSelectDelegate <NSObject>

- (void)mediaCellSelected:(Media *)media;
- (void)mediaCellDeselected:(Media *)media;

@end

@interface MediaBrowserCell : UICollectionViewCell

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL hideCheckbox;
@property (nonatomic, weak) id<MediaBrowserCellMultiSelectDelegate> delegate;

- (void)loadThumbnail;

@end

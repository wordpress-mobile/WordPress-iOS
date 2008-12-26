//
//  WPPhotosListProtocol.h
//  WordPress
//
//  Created by JanakiRam on 27/10/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WPPhotosListProtocol
- (void)useImage:(UIImage*)theImage;
-(id)photosDataSource;
- (void)updatePhotosBadge;
- (void)setHasChanges:(BOOL)aFlag;
@end
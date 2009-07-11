//
//  WPPhotosListProtocol.h
//  WordPress
//
//  Created by JanakiRam on 27/10/08.
//

#import <UIKit/UIKit.h>

@protocol WPPhotosListProtocol

- (void)useImage:(UIImage *)theImage;
- (id)photosDataSource;
- (void)updatePhotosBadge;
- (void)setHasChanges:(BOOL)aFlag;

@end

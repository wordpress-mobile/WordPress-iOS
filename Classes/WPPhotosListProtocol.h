//
//  WPPhotosListProtocol.h
//  WordPress
//
//  Created by Jyothi Swaroop on 27/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WPPhotosListProtocol
- (void)useImage:(UIImage*)theImage;
-(id)photosDataSource;
@end
//
//  PostGeolocationCell.h
//  WordPress
//
//  Created by Eric Johnson on 1/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"
#import "Coordinate.h"

@interface PostGeolocationCell : WPTableViewCell

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address;

@end

//
//  GravatarImageView.h
//  WordPress
//
//  Created by Josh Bassett on 16/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPAsynchronousImageView.h"


@interface GravatarImageView : WPAsynchronousImageView {
@private
    NSString *email;
}

@property (nonatomic, assign) NSString *email;

@end

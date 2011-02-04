//
//  GravatarImageView.h
//  WordPress
//
//  Created by Josh Bassett on 16/07/09.
//

#import <Foundation/Foundation.h>
#import "WPAsynchronousImageView.h"


@interface GravatarImageView : WPAsynchronousImageView {
@private
    NSString *email;
}

@property (nonatomic, assign) NSString *email;

@end

//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>

@interface Blog : NSObject {
@private
    int index;
}

@property int index;

- (id)initWithIndex:(int)blogIndex;

- (UIImage *)favicon;

@end

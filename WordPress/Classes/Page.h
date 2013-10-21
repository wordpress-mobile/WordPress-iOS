//
//  Page.h
//  WordPress
//
//  Created by Jorge Bernal on 12/20/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractPost.h"

@interface Page : AbstractPost

@property (nonatomic, strong) NSNumber * parentID;

@end

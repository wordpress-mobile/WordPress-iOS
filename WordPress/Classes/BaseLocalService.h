//
//  BaseService.h
//  WordPress
//
//  Created by Aaron Douglas on 4/1/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BaseLocalService <NSObject>

@required

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@end

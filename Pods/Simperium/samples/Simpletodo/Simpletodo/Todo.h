//
//  Todo.h
//  Simpletodo
//
//  Created by Michael Johnston on 12-02-15.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Todo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSNumber * done;

@end

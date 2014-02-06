//
//  Config.h
//  Simpletrek
//
//  Created by Michael Johnston on 11-03-08.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestObject.h"

@interface Config : TestObject

@property (nonatomic, strong) NSNumber *warpSpeed;
@property (nonatomic, strong) NSString *binaryFile;
@property (nonatomic, strong) NSString *captainsLog;
@property (nonatomic, strong) NSNumber *shieldsUp;
@property (nonatomic, strong) NSNumber *shieldPercent;
@property (nonatomic, strong) NSDecimalNumber *cost;
@property (nonatomic, strong) NSDate *date;

@end

//
//  ObjectSelector.h
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 5/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPObjectSelector : NSObject

@property (nonatomic, strong, readonly) NSString *string;

+ (MPObjectSelector *)objectSelectorWithString:(NSString *)string;

- (id)initWithString:(NSString *)string;
- (NSArray *)selectFromRoot:(id)root;
- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root;
- (Class)selectedClass;
- (NSString *)description;

@end

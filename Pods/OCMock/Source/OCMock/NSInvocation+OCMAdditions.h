/*
 *  Copyright (c) 2006-2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <Foundation/Foundation.h>

@interface NSInvocation(OCMAdditions)

- (id)getArgumentAtIndexAsObject:(int)argIndex;

- (NSString *)invocationDescription;

- (NSString *)argumentDescriptionAtIndex:(int)argIndex;

- (NSString *)objectDescriptionAtIndex:(int)anInt;
- (NSString *)charDescriptionAtIndex:(int)anInt;
- (NSString *)unsignedCharDescriptionAtIndex:(int)anInt;
- (NSString *)intDescriptionAtIndex:(int)anInt;
- (NSString *)unsignedIntDescriptionAtIndex:(int)anInt;
- (NSString *)shortDescriptionAtIndex:(int)anInt;
- (NSString *)unsignedShortDescriptionAtIndex:(int)anInt;
- (NSString *)longDescriptionAtIndex:(int)anInt;
- (NSString *)unsignedLongDescriptionAtIndex:(int)anInt;
- (NSString *)longLongDescriptionAtIndex:(int)anInt;
- (NSString *)unsignedLongLongDescriptionAtIndex:(int)anInt;
- (NSString *)doubleDescriptionAtIndex:(int)anInt;
- (NSString *)floatDescriptionAtIndex:(int)anInt;
- (NSString *)structDescriptionAtIndex:(int)anInt;
- (NSString *)pointerDescriptionAtIndex:(int)anInt;
- (NSString *)cStringDescriptionAtIndex:(int)anInt;
- (NSString *)selectorDescriptionAtIndex:(int)anInt;

@end

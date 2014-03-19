/* Copyright (c) 2013 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  GTLPlusPlace.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   Google+ API (plus/v1)
// Description:
//   The Google+ API enables developers to build on top of the Google+ platform.
// Documentation:
//   https://developers.google.com/+/api/
// Classes:
//   GTLPlusPlace (0 custom class methods, 4 custom properties)
//   GTLPlusPlaceAddress (0 custom class methods, 1 custom properties)
//   GTLPlusPlacePosition (0 custom class methods, 2 custom properties)

#import "GTLPlusPlace.h"

// ----------------------------------------------------------------------------
//
//   GTLPlusPlace
//

@implementation GTLPlusPlace
@dynamic address, displayName, kind, position;

+ (void)load {
  [self registerObjectClassForKind:@"plus#place"];
}

@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPlaceAddress
//

@implementation GTLPlusPlaceAddress
@dynamic formatted;
@end


// ----------------------------------------------------------------------------
//
//   GTLPlusPlacePosition
//

@implementation GTLPlusPlacePosition
@dynamic latitude, longitude;
@end

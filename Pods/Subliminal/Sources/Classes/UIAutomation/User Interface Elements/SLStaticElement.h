//
//  SLStaticElement.h
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLUIAElement.h"

/**
 Instances of `SLStaticElement` represent user interface elements
 which cannot be dynamically matched to elements within the element hierarchy,
 but which elements have well-defined ("static") UIAutomation representations.

 A UIAutomation representation of an element identifies that element by its position 
 within the element hierarchy: the representation is the path to that element.
 Components of the path are separated by periods and represent indexes into 
 arrays of accessibility elements. For instance, the following representation 
 identifies the first cell of the first table view of an application:
 
    UIATarget.localTarget().frontMostApp().mainWindow().tableViews()[0].cells()[0];
 
 The representation of a particular element may be discovered using Instruments,
 by recording a test script and examining the output of the Automation instrument
 when that element is tapped.
 
 For more information, see the "Understanding the Element Hierarchy" section of
 [this document](https://developer.apple.com/library/ios/#documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/UsingtheAutomationInstrument/UsingtheAutomationInstrument.html).

 @warning `SLStaticElement` does not support the ability of `SLElement` to dynamically
 match objects within the element hierarchy and so is completely dependent 
 on UIAutomation to access and manipulate those elements.

 Note also that for all but app-level elements, a particular static UIAutomation
 representation cannot be guaranteed to continue to identify a particular
 user interface element if the application's element hierarchy changes.

 For these reasons, use of `SLStaticElement` (instead of `SLElement`)
 should be avoided unless absolutely necessary (i.e. a user interface element 
 does not have any properties that can be described by Subliminal without 
 referencing private APIs).
 */
@interface SLStaticElement : SLUIAElement

/**
 Initializes and returns a newly allocated element with the specified 
 UIAutomation representation.

 This is the designated initializer for static elements.
 
 @param UIARepresentation The UIAutomation representation of the element, 
 which identifies the element by its position within the element hierarchy. 
 See the class description for more information.
 @return An initialized static element.
 */
- (instancetype)initWithUIARepresentation:(NSString *)UIARepresentation;

/**
 Informs Subliminal that this element identifies an instance of `UIScrollView`.
 
 Developers must set this to `YES` for an element used to represent a scroll view
 so that Subliminal can work around (or at the least warn of) bugs concerning
 scroll views in various iOS SDK versions:

 *   When this is set to `YES` and tests are running on an iPad simulator or device
     running iOS 5.x, Subliminal will not try to determine tappability when simulating
     user interaction with that scroll view, because UIAutomation will always say
     that the scroll view is not tappable.

 *   When this is set to `YES` and tests are running on a simulator or device (whether iPhone or iPad)
     running iOS 7.x or above, Subliminal will issue a warning if it is asked to drag
     the scroll view, as it will likely fail. See the documentation on
     `[-dragWithStartOffset:endOffset:](-[SLUIAElement dragWithStartOffset:endOffset:])`
     for more information.

 Defaults to `NO`.
 */
@property (nonatomic) BOOL isScrollView;

@end

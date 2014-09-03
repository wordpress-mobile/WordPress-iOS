//
//  SLAccessibilityPath.m
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

#import "SLAccessibilityPath.h"
#import "NSObject+SLAccessibilityHierarchy.h"
#import "SLElement.h"
#import "SLUIAElement+Subclassing.h"
#import "SLMainThreadRef.h"

#import <objc/runtime.h>


#pragma mark NSObject (SLAccessibilityPath_Internal) interface

/**
 The methods in the NSObject (SLAccessibilityPath_Internal) category are used
 by `SLAccessibilityPath` in the process of constructing, sanitizing, binding,
 and serializing paths.
 */
@interface NSObject (SLAccessibilityPath_Internal)

/// ----------------------------------------
/// @name Constructing paths
/// ----------------------------------------

/**
 Creates and returns an array of objects that form a path through an accessibility
 hierarchy between the receiver and the object [matching](-[SLElement matchesObject:])
 the specified element.

 If favoringSubviews is YES, the method will construct a path that is, as much
 as is possible, comprised of UIViews; otherwise, it will construct a path that is,
 as much as is possible, comprised of UIAccessibilityElements.

 These paths may contain more objects than exist in the accessibility hierarchy
 recognized by UIAutomation; they correspond to the "raw" view and accessibility
 element paths used to initialize an SLAccessibilityPath.

 @param element The element to which corresponds the object that is to be
 the terminus of the path.
 @param favoringSubviews YES if the search for a path should favor UIViews;
 otherwise, the search should favor UIAccessibilityElements.
 @return A path between the receiver and the object matching element,
 or `nil` if an object matching element is not found within the accessibility hierarchy
 rooted in the receiver.
 */
- (NSArray *)rawAccessibilityPathToElement:(SLElement *)element favoringSubviews:(BOOL)favoringSubviews;

/// ----------------------------------------
/// @name Binding and serializing paths
/// ----------------------------------------

/**
 Returns a Boolean value that indicates whether the receiver
 has loaded -slReplacementAccessibilityIdentifier.

 This does not check whether a superclass of the receiver may have loaded
 -slReplacementAccessibilityIdentifier.

 @return YES if +loadSLReplacementAccessibilityIdentifier has been sent
 to the receiver, otherwise NO;
 */
+ (BOOL)slReplacementAccessibilityIdentifierHasBeenLoaded;

/**
 Replaces the receiver's implementation of -accessibilityIdentifier
 with -slReplacementAccessibilityIdentifier.

 This method is idempotent.

 Note that -slReplacementAccessibilityIdentifier will return the true
 value of -accessibilityIdentifier unless -useSLReplacementAccessibilityIdentifier
 is YES.
 */
+ (void)loadSLReplacementAccessibilityIdentifier;

/**
 Indicates whether -slReplacementAccessibilityIdentifier should return
 the receiver's [replacement accessibility identifier](-slReplacementAccessibilityIdentifier),
 or the object's [true accessibility identifier](-slTrueAccessibilityIdentifier).

 When this is set to YES, the receiver's class will [load -slReplacementAccessibilityIdentifier]
 (+loadSLReplacementAccessibilityIdentifier) if necessary.
 */
@property (nonatomic) BOOL useSLReplacementAccessibilityIdentifier;

/**
 Returns a replacement for -[UIAccessibilityIdentification accessibilityIdentifier]
 if -useSLReplacementAccessibilityIdentifier is YES.

 @warning This method must not be called unless +loadSLReplacementAccessibilityIdentifier
 has been previously sent to the receiver's class or a superclass.

 @return A replacement for -accessibilityIdentifier that is unique to the receiver,
 if -useSLReplacementAccessibilityIdentifier is YES; otherwise, the value
 returned by the receiver's true implementation of -accessibilityIdentifier.
 **/
- (NSString *)slReplacementAccessibilityIdentifier;

/**
 Returns the true accessibility identifier of the receiver.

 @warning This is intentionally unimplemented. Its implementation is set
 when +loadSLReplacementAccessibilityIdentifier is sent to the receiver's class.

 @return The value returned by the receiver's implementation of -accessibilityIdentifier
 prior to -slReplacementAccessibilityIdentifier having been [loaded](+loadSLReplacementAccessibilityIdentifier).
 */
- (NSString *)slTrueAccessibilityIdentifier;

@end


#pragma mark - SLAccessibilityPath interface

@interface SLAccessibilityPath ()

/**
 Creates and returns an array containing only those objects from
 the specified accessibility element path that will appear in the accessibility
 hierarchy as understood by UIAutomation.

 These objects corresponds closely, but not entirely, to the _views_ that will appear
 in the accessibility hierarchy.

 @param accessibilityElementPath The predominantly-UIAccessibilityElement path to filter.
 @param viewPath A predominantly-UIView path corresponding to accessibilityElementPath,
 to be used to filter accessibilityElementPath.
 @return A path that contains only those elements that appear in the accessibility
 hierarchy as understood by UIAutomation.
 */
+ (NSArray *)filterRawAccessibilityElementPath:(NSArray *)accessibilityElementPath
                              usingRawViewPath:(NSArray *)viewPath;

/**
 Creates and returns an array containing only those objects from
 the specified view path that appear in the accessibility hierarchy
 as understood by UIAutomation.

 These do not comprise only those views that are accessibility elements
 according to -[NSObject isAccessibilityElement].

 @param viewPath The predominantly-UIView path to filter.
 @return A path containing only those views that appear in
 the accessibility hierarchy as understood by UIAutomation.
 */
+ (NSArray *)filterRawViewPath:(NSArray *)viewPath;

/**
 Creates and returns an array comprised of the components from the specified
 path, wrapped in SLMainThreadRefs.

 The path returned will weakly reference the original components
 and so can be safely retained on a background thread

 @param path A path to map using SLMainThreadRefs.
 @return An array comprised of the components from path, wrapped in SLMainThreadRefs.
 */
+ (NSArray *)mapPathToBackgroundThread:(NSArray *)path;

/**
 Initializes and returns a newly allocated accessibility path
 with the specified component paths.

 The accessibility element path should prioritize paths along UIAccessibilityElements
 to a matching object, while the view path should prioritize paths comprising
 UIViews. If this is done, every view in the accessibility element path will exist
 in the view path, and each object in the accessibility element path that mocks
 a view, will mock a view from the view path.

 It is the accessibility element path that (when [serialized](-UIARepresentation))
 matches the path that UIAutomation would use to identify the accessibility
 path's referent. Providing a view path enables clients to examine
 the actual object that was matched in the event that the path's referent is a view.

 @warning The accessibility path filters the component paths in the process of
 initialization. If, after filtering, either path is empty, the accessibility
 path will be released and this method will return nil.

 @param accessibilityElementPath A path that predominantly traverses
 UIAccessibilityElements.
 @param viewPath A path that predominantly traverse UIViews.
 @return An initialized accessibility path, or `nil` if the object couldn't be created.
 */
- (instancetype)initWithRawAccessibilityElementPath:(NSArray *)accessibilityElementPath
                                        rawViewPath:(NSArray *)viewPath;

@end


#pragma mark - NSObject (SLAccessibilityPath) implementation

@implementation NSObject (SLAccessibilityPath)

- (SLAccessibilityPath *)slAccessibilityPathToElement:(SLElement *)element {
    NSArray *accessibilityElementPath = [self rawAccessibilityPathToElement:element favoringSubviews:NO];
    NSArray *viewPath = [self rawAccessibilityPathToElement:element favoringSubviews:YES];

    return [[SLAccessibilityPath alloc] initWithRawAccessibilityElementPath:accessibilityElementPath
                                                                rawViewPath:viewPath];
}

- (NSArray *)rawAccessibilityPathToElement:(SLElement *)element favoringSubviews:(BOOL)favoringSubviews {
    for (NSObject *child in [self slChildAccessibilityElementsFavoringSubviews:favoringSubviews]) {
        NSArray *path = [child rawAccessibilityPathToElement:element favoringSubviews:favoringSubviews];
        if (path) {
            NSMutableArray *pathWithSelf = [path mutableCopy];
            [pathWithSelf insertObject:self atIndex:0];
            return pathWithSelf;
        }
    }

    if ([element matchesObject:self]) {
        return [NSArray arrayWithObject:self];
    }
    return nil;
}

static const void *const kSLReplacementAccessibilityIdentifierHasBeenLoadedKey = &kSLReplacementAccessibilityIdentifierHasBeenLoadedKey;
+ (BOOL)slReplacementAccessibilityIdentifierHasBeenLoaded {
    if ([objc_getAssociatedObject(self, kSLReplacementAccessibilityIdentifierHasBeenLoadedKey) boolValue]) {
        return YES;
    }

    // -slReplacementAccessibilityIdentifier might have been loaded on a superclass;
    // if the subclass doesn't override -accessibilityIdentifier,
    // it's loaded on the subclass too
    Method accessibilityIdentifierMethod = class_getInstanceMethod(self, @selector(accessibilityIdentifier));
    IMP accessibilityIdentifierImp = method_getImplementation(accessibilityIdentifierMethod);

    Method replacementIdentifierMethod = class_getInstanceMethod(self, @selector(slReplacementAccessibilityIdentifier));
    IMP replacementIdentifierIMP = method_getImplementation(replacementIdentifierMethod);

    if (accessibilityIdentifierImp == replacementIdentifierIMP) {
        [self setSLReplacementAccessibilityIdentifierHasBeenLoaded];
        return YES;
    }

    return NO;
}

+ (void)setSLReplacementAccessibilityIdentifierHasBeenLoaded {
    objc_setAssociatedObject(self, kSLReplacementAccessibilityIdentifierHasBeenLoadedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)loadSLReplacementAccessibilityIdentifier {
    if (![self slReplacementAccessibilityIdentifierHasBeenLoaded]) {
        // we use class_getInstanceMethod to get the original IMP
        // rather than using the return value of class_replaceMethod
        // because class_replaceMethod returns NULL when it overrides a superclass' implementation
        Method originalIdentifierMethod = class_getInstanceMethod(self, @selector(accessibilityIdentifier));
        IMP originalIdentifierImp = method_getImplementation(originalIdentifierMethod);

        Method replacementIdentifierMethod = class_getInstanceMethod(self, @selector(slReplacementAccessibilityIdentifier));
        IMP replacementIdentifierIMP = method_getImplementation(replacementIdentifierMethod);
        const char *replacementIdentifierTypes = method_getTypeEncoding(replacementIdentifierMethod);

        (void)class_replaceMethod(self, method_getName(originalIdentifierMethod), replacementIdentifierIMP, replacementIdentifierTypes);
        class_addMethod(self, @selector(slTrueAccessibilityIdentifier), originalIdentifierImp, replacementIdentifierTypes);

        [self setSLReplacementAccessibilityIdentifierHasBeenLoaded];
    }
}

static const void *const kUseSLReplacementIdentifierKey = &kUseSLReplacementIdentifierKey;
- (BOOL)useSLReplacementAccessibilityIdentifier {
    return [objc_getAssociatedObject(self, kUseSLReplacementIdentifierKey) boolValue];
}

- (void)setUseSLReplacementAccessibilityIdentifier:(BOOL)useSLReplacementAccessibilityIdentifier {
    if (useSLReplacementAccessibilityIdentifier) {
        [[self class] loadSLReplacementAccessibilityIdentifier];
    }
    objc_setAssociatedObject(self, kUseSLReplacementIdentifierKey, @(useSLReplacementAccessibilityIdentifier), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)slReplacementAccessibilityIdentifier {
    if (self.useSLReplacementAccessibilityIdentifier) {
        return [NSString stringWithFormat:@"%@: %p", [self class], self];
    } else {
        // If this line crashes, something's wrong: this method should only be called
        // if either the receiver's class or a superclass thereof
        // have loaded -slReplacementAccessibilityIdentifier.
        return [self slTrueAccessibilityIdentifier];
    }
}

@end


#pragma mark - SLAccessibilityPath implementation

@implementation SLAccessibilityPath {
    NSArray *_accessibilityElementPath;
    SLMainThreadRef *_destinationRef;
}

+ (NSArray *)filterRawAccessibilityElementPath:(NSArray *)accessibilityElementPath
                              usingRawViewPath:(NSArray *)viewPath {
    NSMutableArray *filteredArray = [[NSMutableArray alloc] init];
    __block NSUInteger viewPathIndex = 0;
    [accessibilityElementPath enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id objectFromAccessibilityElementPath = obj;
        id currentViewPathObject =  (viewPathIndex < [viewPath count] ?
                                     [viewPath objectAtIndex:viewPathIndex] : nil);

        // For each objectFromAccessibilityElementPath, if it mocks a view,
        // that view will be in viewAccessibilityPath. Elements from the
        // accessibilityElementPath that do not mock views (i.e. user-created
        // accessibility elements) will exist at the end of accessibilityElementPath,
        // and will also exist at the end of viewAccessibilityPath.
        if (![objectFromAccessibilityElementPath isKindOfClass:[UIView class]]) {
            while (![UIView elementObject:objectFromAccessibilityElementPath isMockingViewObject:currentViewPathObject] &&
                   currentViewPathObject) {
                viewPathIndex++;
                currentViewPathObject = (viewPathIndex < [viewPath count] ?
                                         [viewPath objectAtIndex:viewPathIndex] : nil);
            }
        }

        // Views that will appear in the hierarchy are always included
        if ([objectFromAccessibilityElementPath isKindOfClass:[UIView class]]) {
            viewPathIndex++;
            if ([objectFromAccessibilityElementPath willAppearInAccessibilityHierarchy]) {
                [filteredArray addObject:objectFromAccessibilityElementPath];
            }

            // Mock views are included in the hierarchy depending on the view
        } else if ([UIView elementObject:objectFromAccessibilityElementPath isMockingViewObject:currentViewPathObject]) {
            viewPathIndex++;
            if ([(UIView *)currentViewPathObject elementMockingSelfWillAppearInAccessibilityHierarchy]) {
                [filteredArray addObject:objectFromAccessibilityElementPath];
            }

            // At this point, we only add the current objectFromAccessibilityElementPath
            // if we can be sure it's not mocking a view (by us having exhausted
            // the views in the view path) and it will appear in the accessibility hierarchy
        } else if ((![currentViewPathObject isKindOfClass:[UIView class]] &&
                    [objectFromAccessibilityElementPath willAppearInAccessibilityHierarchy])){
            [filteredArray addObject:objectFromAccessibilityElementPath];
        }
    }];
    return filteredArray;
}

+ (NSArray *)filterRawViewPath:(NSArray *)viewPath {
    NSMutableArray *filteredPath = [[NSMutableArray alloc] init];
    [viewPath enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // We will need the UIView path to contain any objects that will
        // appear in the accessibility hierarchy, as well as any objects
        // that will be accompanied by mock views that will appear in the
        // accessibility hierarchy
        if ([obj willAppearInAccessibilityHierarchy] ||
            ([obj isKindOfClass:[UIView class]] &&
             [(UIView *)obj elementMockingSelfWillAppearInAccessibilityHierarchy])) {
                [filteredPath addObject:obj];
            }
    }];
    return filteredPath;
}

// As mentioned in the methods below where references' targets are retrieved:
// SLAccessibilityPath methods should not throw exceptions if
// references' targets are found to have fallen out of scope,
// because an exception thrown inside a dispatched block cannot be caught
// outside that block.
//
// SLAccessibilityPath's approach to error handling is described
// in the header.
+ (NSArray *)mapPathToBackgroundThread:(NSArray *)path {
    NSMutableArray *mappedPath = [[NSMutableArray alloc] initWithCapacity:[path count]];
    for (id obj in path) {
        [mappedPath addObject:[SLMainThreadRef refWithTarget:obj]];
    }
    return mappedPath;
}

- (instancetype)initWithRawAccessibilityElementPath:(NSArray *)accessibilityElementPath
                                        rawViewPath:(NSArray *)viewPath {
    self = [super init];
    if (self) {
        NSArray *filteredAccessibilityElementPath = [[self class] filterRawAccessibilityElementPath:accessibilityElementPath
                                                                                   usingRawViewPath:viewPath];
        NSArray *filteredViewPath = [[self class] filterRawViewPath:viewPath];

        // If, after filtering, the accessibility element path contains no elements,
        // or filtering removes the last element of the path (the path's destination)
        // the path is invalid
        if (![filteredAccessibilityElementPath count] ||
            ([filteredAccessibilityElementPath lastObject] != [accessibilityElementPath lastObject])) {
            self = nil;
            return self;
        }

        // the path's destination is given by the last element in the view path
        // (because that contains real and not mock views, as well as accessibility
        // elements generated by the application vs. the system),
        // unless it was filtered (e.g. it was a UILabel in a UITableViewCell)
        id destination;
        if ([filteredViewPath count] && ([filteredViewPath lastObject] == [viewPath lastObject])) {
            destination = [filteredViewPath lastObject];
        } else {
            destination = [filteredAccessibilityElementPath lastObject];
        }

        _accessibilityElementPath = [[self class] mapPathToBackgroundThread:filteredAccessibilityElementPath];
        _destinationRef = [SLMainThreadRef refWithTarget:destination];
    }
    return self;
}

- (void)examineLastPathComponent:(void (^)(NSObject *lastPathComponent))block {
    dispatch_sync(dispatch_get_main_queue(), ^{
        block([_destinationRef target]);
    });
}

- (void)bindPath:(void (^)(SLAccessibilityPath *boundPath))block {
    // To bind the path to a unique destination, each object in the mock view path
    // is caused to return a unique replacement identifier. This is done by swizzling
    // -accessibilityIdentifier because some objects' identifiers cannot be set directly
    // (e.g. UISegmentedControl, some mock views).
    //
    // @warning This implementation assumes that there's only one SLAccessibilityPath
    // binding/bound at a time. It also assumes that it's unlikely that clients
    // other than UIAccessibility will try to read the elements' identifiers
    // while bound.
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (SLMainThreadRef *objRef in _accessibilityElementPath) {
            NSObject *obj = [objRef target];

            // see note on +mapPathToBackgroundThread:;
            // we only throw a fatal exception if there *are* objects in the path
            // that differ from our assumptions
            NSAssert(!obj || [obj respondsToSelector:@selector(accessibilityIdentifier)],
                     @"elements in the view path must conform to UIAccessibilityIdentification");

            obj.useSLReplacementAccessibilityIdentifier = YES;
        }
    });

    block(self);

    // Set the objects to use the original -accessibilityIdentifier again.
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (SLMainThreadRef *objRef in _accessibilityElementPath) {
            NSObject *obj = [objRef target];
            obj.useSLReplacementAccessibilityIdentifier = NO;
        }
    });
}

- (NSString *)UIARepresentation {
    __block NSMutableString *uiaRepresentation = [@"UIATarget.localTarget().frontMostApp()" mutableCopy];
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (SLMainThreadRef *objRef in _accessibilityElementPath) {
            NSObject *obj = [objRef target];

            // see note on +mapPathToBackgroundThread:
            // we only throw a fatal exception if there *are* objects in the path
            // that differ from our assumptions
            NSAssert(!obj || [obj respondsToSelector:@selector(accessibilityIdentifier)],
                     @"elements in the mock view path must conform to UIAccessibilityIdentification");

            NSString *identifier = [obj performSelector:@selector(accessibilityIdentifier)];
            NSAssert(!obj || [identifier length], @"Accessibility paths can only be serialized while bound.");

            [uiaRepresentation appendFormat:@".elements()['%@']", [identifier slStringByEscapingForJavaScriptLiteral]];
        }
    });
    return uiaRepresentation;
}

@end

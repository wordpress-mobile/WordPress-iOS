#import "Post.h"
#import "Media.h"
#import "PostCategory.h"
#import "Coordinate.h"
#import "NSMutableDictionary+Helpers.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"

@implementation Post

@dynamic geolocation;
@dynamic tags;
@dynamic postFormat;
@dynamic latitudeID;
@dynamic longitudeID;
@dynamic publicID;
@dynamic categories;
@synthesize specialType;

#pragma mark - NSManagedObject subclass methods

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];

    self.specialType = nil;
}

#pragma mark -

- (NSString *)categoriesText
{
    return [[[self.categories valueForKey:@"categoryName"] allObjects] componentsJoinedByString:@", "];
}

- (NSString *)postFormatText
{
    NSDictionary *allFormats = self.blog.postFormats;
    NSString *formatText = self.postFormat;
    if ([allFormats objectForKey:self.postFormat]) {
        formatText = [allFormats objectForKey:self.postFormat];
    }
    if ((formatText == nil || [formatText isEqualToString:@""]) && [allFormats objectForKey:@"standard"]) {
        formatText = [allFormats objectForKey:@"standard"];
    }
    return formatText;
}

- (void)setPostFormatText:(NSString *)postFormatText
{
    __block NSString *format = nil;
    [self.blog.postFormats enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:postFormatText]) {
            format = (NSString *)key;
            *stop = YES;
        }
    }];
    self.postFormat = format;
}

- (void)setCategoriesFromNames:(NSArray *)categoryNames
{
    [self.categories removeAllObjects];
    NSMutableSet *categories = nil;

    for (NSString *categoryName in categoryNames) {
        NSSet *results = [self.blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName = %@", categoryName]];
        if (results && (results.count > 0)) {
            if (categories == nil) {
                categories = [NSMutableSet setWithSet:results];
            } else {
                [categories unionSet:results];
            }
        }
    }

    if (categories && (categories.count > 0)) {
        self.categories = categories;
    }
}

- (BOOL)hasSiteSpecificChanges
{
    if ([super hasSiteSpecificChanges]) {
        return YES;
    }

    Post *original = (Post *)self.original;

    if ((self.postFormat != original.postFormat) && (![self.postFormat isEqual:original.postFormat])) {
        return YES;
    }

    if (![self.categories isEqual:original.categories]) {
        return YES;
    }

    return NO;
}

- (BOOL)hasCategories
{
    if ([self.categories count] > 0) {
        return true;
    }

    return false;
}

- (BOOL)hasTags
{
    if ([[self.tags trim] length] > 0) {
        return true;
    }

    return false;
}

#pragma mark - Unsaved changes

- (BOOL)hasLocalChanges
{
    if (![self isRevision]) {
        return NO;
    }
    
    if ([super hasLocalChanges]) {
        return YES;
    }
    
    Post *original = (Post *)self.original;
    if (!original) {
        return NO;
    }
    
    if (([self.tags length] != [original.tags length]) && (![self.tags isEqual:original.tags])) {
        return YES;
    }
    
    CLLocationCoordinate2D coord1 = self.geolocation.coordinate;
    CLLocationCoordinate2D coord2 = original.geolocation.coordinate;
    if ((coord1.latitude != coord2.latitude) || (coord1.longitude != coord2.longitude)) {
        return YES;
    }
    
    return NO;
}

#pragma mark - WPPostContentViewProvider Methods

- (NSString *)authorNameForDisplay
{
    return self.author;
}

- (NSURL *)blogURL
{
    return nil;
}

- (NSInteger)commentCount
{
    return 0;
}

- (NSInteger)likeCount
{
    return 0;
}

- (BOOL)hasCommented
{
    return NO;
}

- (BOOL)hasLiked
{
    return NO;
}

- (NSString *)titleForDisplay
{
    NSString *title = self.postTitle ? self.postTitle : @"";
    title = [self.postTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [title stringByDecodingXMLCharacters];
}

- (NSString *)authorForDisplay
{
    return self.author;
}

- (NSString *)blogNameForDisplay
{
    return self.blog.blogName;
}

- (NSString *)contentForDisplay
{
    return self.content;
}

- (NSString *)contentPreviewForDisplay
{
    NSString *content = self.content ? self.content : @"";
    return [[[content stringByStrippingHTML] stringByDecodingXMLCharacters] trim];
}

- (NSString *)gravatarEmailForDisplay
{
    return nil;
}

- (NSURL *)avatarURLForDisplay
{
    return nil;
}

@end

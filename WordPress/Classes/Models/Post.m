#import "Post.h"
#import "Media.h"
#import "PostCategory.h"
#import "Coordinate.h"
#import "NSDate+StringFormatting.h"
#import "NSMutableDictionary+Helpers.h"
#import "NSString+Helpers.h"
#import "ContextManager.h"
#import <WordPressShared/NSString+XMLExtensions.h>

NSString * const PostTypeDefaultIdentifier = @"post";

@interface Post()
@property (nonatomic, strong) NSString *storedContentPreviewForDisplay;
@end

@implementation Post

@dynamic commentCount;
@dynamic likeCount;
@dynamic geolocation;
@dynamic tags;
@dynamic postType;
@dynamic postFormat;
@dynamic latitudeID;
@dynamic longitudeID;
@dynamic publicID;
@dynamic categories;
@synthesize specialType;
@synthesize storedContentPreviewForDisplay;

#pragma mark - NSManagedObject subclass methods

- (void)awakeFromFetch
{
    [super awakeFromFetch];

    [self buildContentPreview];
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];

    self.specialType = nil;
}

- (void)willSave
{
    [super willSave];
    if ([self isDeleted]) {
        return;
    }
    [self buildContentPreview];
}


#pragma mark -

- (void)buildContentPreview
{
    NSString *str = self.mt_excerpt;
    if ([str length]) {
        str = [NSString makePlainText:str];
    } else {
        str = [BasePost summaryFromContent:self.content];
    }
    self.storedContentPreviewForDisplay = str ? str : @"";
}

- (NSString *)categoriesText
{
    return [[[self.categories valueForKey:@"categoryName"] allObjects] componentsJoinedByString:@", "];
}

- (NSString *)postFormatText
{
    return [self.blog postFormatTextFromSlug:self.postFormat];
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
    [self removeCategories:self.categories];
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
        [self addCategories:categories];
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

- (NSString *)titleForDisplay
{
    NSString *title = [self.postTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ?: @"";
    title = [title stringByDecodingXMLCharacters];
    if ([title length] == 0 && [[self contentPreviewForDisplay] length] == 0 && ![self hasRemote]) {
        title = NSLocalizedString(@"(no title)", @"Let's a user know that a local draft does not have a title.");
    }
    return title;
}

- (NSString *)contentPreviewForDisplay
{
    if (self.storedContentPreviewForDisplay == nil) {
        [self buildContentPreview];
    }
    return self.storedContentPreviewForDisplay;
}

- (NSString *)statusForDisplay
{
    NSString *statusString = [self statusTitle];
    if ([self.status isEqualToString:PostStatusPublish] || [self.status isEqualToString:PostStatusDraft]) {
        statusString = nil;
    }
    if (![self hasRemote]) {
        NSString *localOnly = NSLocalizedString(@"Local", @"A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.");
        if (statusString) {
            statusString = [NSString stringWithFormat:@"%@, %@", statusString, localOnly];
        } else {
            statusString = localOnly;
        }
    }
    return statusString;
}

- (NSURL *)featuredImageURLForDisplay
{
    NSURL *url = [NSURL URLWithString:self.pathForDisplayImage];
    return url;
}

- (NSInteger)numberOfComments
{
    if (self.commentCount) {
        return [self.commentCount integerValue];
    }
    return 0;
}

- (NSInteger)numberOfLikes
{
    if (self.likeCount) {
        return [self.likeCount integerValue];
    }
    return 0;
}


@end

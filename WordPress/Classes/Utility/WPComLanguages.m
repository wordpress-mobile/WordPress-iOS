#import "WPComLanguages.h"

@interface WPComLanguages()

@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, assign) BOOL rtl;

@end

@implementation WPComLanguages

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeLanguages];
        _rtl = ([NSLocale characterDirectionForLanguage:[[NSLocale preferredLanguages] objectAtIndex:0]] == NSLocaleLanguageDirectionRightToLeft);
    }
    return self;
}

+ (NSDictionary *)currentLanguage
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSDictionary *currentLanguage = [WPComLanguages languageDataForLocale:language];
    if (currentLanguage == nil) {
        currentLanguage = [WPComLanguages languageDataForLocale:@"en"];
    }

    return currentLanguage;
}

+ (NSArray *)allLanguages
{
    return [self sharedInstance].languages;
}

+ (NSDictionary *)languageDataForLocale:(NSString *)locale
{
    NSArray *languages = [self sharedInstance].languages;

    for (NSDictionary *languageData in languages) {
        if ([[languageData objectForKey:@"slug"] isEqualToString:locale]) {
            return languageData;
        }
    }

    return nil;
}

+ (BOOL)isRightToLeft
{
    return [self sharedInstance].rtl;
}

#pragma mark - Private Methods

+ (WPComLanguages *)sharedInstance
{
    static WPComLanguages *sharedInstance = nil;

    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (void)initializeLanguages
{
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* plistPath = [bundle pathForResource:@"DotCom-Languages" ofType:@"plist"];
    _languages = [[NSArray alloc] initWithContentsOfFile:plistPath];
}

@end

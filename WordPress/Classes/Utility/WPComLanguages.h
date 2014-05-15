#import <Foundation/Foundation.h>

@interface WPComLanguages : NSObject

+ (NSDictionary *)currentLanguage;
+ (NSArray *)allLanguages;
+ (NSDictionary *)languageDataForLocale:(NSString *)locale;
+ (BOOL)isRightToLeft;

@end

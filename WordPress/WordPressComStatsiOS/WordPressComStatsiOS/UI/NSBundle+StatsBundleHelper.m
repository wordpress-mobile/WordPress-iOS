#import "NSBundle+StatsBundleHelper.h"
#import "WPStatsViewController.h"

@implementation NSBundle (StatsBundleHelper)

+ (NSBundle *)statsBundle
{
    NSBundle *statsBundle = [NSBundle bundleForClass:[WPStatsViewController class]];
    NSString *path = [statsBundle pathForResource:@"WordPressCom-Stats-iOS" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    
    return bundle ?: statsBundle;
}

@end

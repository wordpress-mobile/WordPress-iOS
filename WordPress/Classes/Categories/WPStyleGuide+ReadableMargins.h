#import <WordPressShared/WPStyleGuide.h>

@interface WPStyleGuide (ReadableMargins)


+ (void)resetReadableMarginsForTableView:(UITableView *)tableView __deprecated_msg("Follow readable margins via constraints or instead explicitly set setCellLayoutMarginsFollowReadableWidth on UITableView.");

@end

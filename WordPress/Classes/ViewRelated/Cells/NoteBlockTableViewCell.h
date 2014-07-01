#import <Foundation/Foundation.h>



typedef void (^NotificationUrlHandler)(NSURL *url);

@protocol NoteBlockTableViewCell <NSObject>

+ (CGFloat)heightWithText:(NSString *)text;
+ (NSString *)reuseIdentifier;

@end

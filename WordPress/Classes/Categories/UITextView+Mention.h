#import <UIKit/UIKit.h>

@interface UITextView (Mention)

/**
 If the user deletes a part of a word starting with @ sign, it will delete the whole word

 Should be used in shouldChangeTextInRange:replacementText:

 @return if a tag was deleted or not
 */
- (BOOL)deleteTagForTextChangeInRange:(NSRange)range replacementText:(NSString *)text;

@end

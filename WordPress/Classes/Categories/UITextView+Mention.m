#import "UITextView+Mention.h"

@implementation UITextView (Mention)

// returns the result of if a tag was deleted or not
- (BOOL)deleteTagForTextChangeInRange:(NSRange)range replacementText:(NSString *)text
{
    // deleting or replacing text
    if (range.length > 0) {
        NSString *currentText = self.text;

        // check if the first character of the text being edited (selected) is space (ex. "@someTag ")
        if ([[currentText substringWithRange:NSMakeRange(range.location, 1)] isEqualToString:@" "]) {
            return NO;
        }

        /**
         In order to find the beginning of the word currently being edited:
         Find the text before the edited part and reverse check for the first space character
         If there is no space character in the text, it means it is the first word
         Store the location of the first character position of the word
         */

        NSString *textBeforeEditedPart = [currentText substringToIndex:range.location];
        __block NSInteger firstCharacterPosition = 0;

        [textBeforeEditedPart enumerateSubstringsInRange:NSMakeRange(0, [textBeforeEditedPart length])
                                                 options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                                  if ([substring isEqualToString:@" "]) {
                                                      firstCharacterPosition = substringRange.location + 1; // +1 is for the length of @" "
                                                      *stop = YES;
                                                  }
                                              }];

        // Check if the first character at the position we found is @ sign and if not return
        if (![[currentText substringWithRange:NSMakeRange(firstCharacterPosition, 1)] isEqualToString:@"@"]) {
            return NO;
        }

        /**
         If the user is deleting the tag from the middle, we want to make sure it deletes the whole word
         To do that, first find the end position after the @ signed word. Then, while calculating the new
         length of the range that will be changed, include the part after the cursor to the end of the word.
         */

        NSString *textAfterAtSign = [currentText substringFromIndex:firstCharacterPosition];
        __block NSInteger taggedWordEndPosition = firstCharacterPosition;

        [currentText enumerateSubstringsInRange:NSMakeRange(firstCharacterPosition, [textAfterAtSign length])
                                        options:NSStringEnumerationByComposedCharacterSequences
                                     usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                         taggedWordEndPosition = substringRange.location + substringRange.length;
                                         if ([substring isEqualToString:@" "]) {
                                             *stop = YES;
                                         }
                                     }];

        NSInteger newLength = MAX(range.location + range.length, taggedWordEndPosition) - firstCharacterPosition;
        self.text = [currentText stringByReplacingCharactersInRange:NSMakeRange(firstCharacterPosition, newLength) withString:text];

        // Change the cursor position to where the user left it off since we are changing the text manually
        self.selectedRange = NSMakeRange(firstCharacterPosition, 0);

        return YES;
    }
    return NO;
}

@end

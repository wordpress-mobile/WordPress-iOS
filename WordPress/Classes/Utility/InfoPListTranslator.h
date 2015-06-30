#import <Foundation/Foundation.h>

/**
 This class purpose is to feed strings existing on the Info.plist file to the translation scripts.
 When the tranlators provide the translation the tokens will show up in the Localizable.strings files.
 Then the strings need to be copied over to the correct InfoPList.strings file for each language
 */
@interface InfoPListTranslator : NSObject

+ (void)translateStrings;

@end

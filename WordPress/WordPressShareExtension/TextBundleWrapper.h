//
//  TextBundle.h
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kUTTypeMarkdown;
extern NSString * const kUTTypeTextBundle;

extern NSString * const TextBundleErrorDomain;

typedef NS_ENUM(NSInteger, TextBundleError)
{
    TextBundleErrorInvalidFormat,
};

@interface TextBundleWrapper : NSObject


/**
 The plain text contents, read from text.* (whereas * is an arbitrary file extension)
 */
@property (strong, nonnull) NSString *text;

/**
 File wrapper represeting the whole TextBundle.
 */
@property (readonly, nullable, nonatomic) NSFileWrapper *fileWrapper;

/**
 File wrapper containing all asset files referenced from the plain text file.
 */
@property (strong, nonnull) NSFileWrapper *assetsFileWrapper;

/**
 The version number of the file format. Version 2 (latest) is used as default.
 */
@property (strong) NSNumber *version;

/**
 The UTI of the text.* file.
 */
@property (strong) NSString *type;

/**
 Whether or not the bundle is a temporary container solely used for exchanging a document between applications. Defaults to “false”.
 */
@property (strong) NSNumber *transient;

/**
 The bundle identifier of the application that created the file.
 */
@property (strong) NSString *creatorIdentifier;

/**
 Dictionary of application-specific information. Application-specific information must be stored inside a nested dictionary.
 
 The dictionary is referenced by a key using the application bundle identifier (e.g. com.example.myapp).
 This dictionary should contain at least a version number to ensure backwards compatibility.
 
 Example:
 "com.example.myapp": {
    "version": 9,
    "customKey": "aCustomValue"
 }
 */
@property (strong) NSMutableDictionary *metadata;


/**
 Returns true if type name is conforming to the TextBundle type

 @param typeName The string that identifies the file type.
 @return True if type name is conforming to the textbundle type
 */
+ (BOOL)isTextBundleType:(NSString *)typeName;


/**
 Initialize a TextBundleWrapper instance from URL

 @param url URL of the file the TextBundleWrapper is to represent.
 @param options flags for reading the TextBundleWrapper at url. See NSFileWrapperReadingOptions for possible values.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Pass NULL if you do not want error information.
 @return A new TextBundleWrapper for the content at url.
 */
- (instancetype)initWithContentsOfURL:(NSURL *)url options:(NSFileWrapperReadingOptions)options error:(NSError **)error;


/**
 Initialize a TextBundleWrapper instance from a NSFileWrapper

 @param fileWrapper The NSFileWrapper representing the TextBundle
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Pass NULL if you do not want error information.
 @return A new TextBundleWrapper for the content of the fileWrapper.
 */
- (instancetype)initWithFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)error;


/**
 Writes the TextBundleWrapper content to a given file-system URL.

 @param url URL of the file to which the TextBundleWrapper's contents are written.
 @param options flags for writing to the file located at url. See NSFileWrapperWritingOptions for possible values.
 @param originalContentsURL The location of a previous revision of the contents being written.
 The default implementation of this method attempts to avoid unnecessary I/O by writing hard links to regular files
 instead of actually writing out their contents when the contents have not changed.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Pass NULL if you do not want error information.
 @return YES when the write operation is successful. If not successful, returns NO after setting error to an NSError object that describes the reason why the TextBundleWrapper's contents could not be written.
 */
- (BOOL)writeToURL:(NSURL *)url options:(NSFileWrapperWritingOptions)options originalContentsURL:(nullable NSURL *)originalContentsURL error:(NSError **)error;


/**
 Return the filewrapper represeting an asset or nil if there is no asset named with filename

 @param filename A filename in the asset/ folder
 @return A NSFilewrapper represeting filename or nil it the file doesn't exist
 */
- (NSFileWrapper *)fileWrapperForAssetFilename:(NSString *)filename;



/**
 Add a NSFileWrapper to the TextBundleWrapper's assetFileWrapper.
 If a file have the same name of an exiting file the name will be changed and if the file has the same content this method will do nothing.

 @param assetFileWrapper A NSFileWrapper to add to the TextBundleWrapper's assets
 @return The final filename of the added asset.
 */
- (NSString *)addAssetFileWrapper:(NSFileWrapper *)assetFileWrapper;

@end

NS_ASSUME_NONNULL_END

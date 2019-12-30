//
//  TextBundle.m
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import "TextBundleWrapper.h"
#import <CoreServices/CoreServices.h>

// Filenames constants
NSString * const kTextBundleInfoFileName = @"info.json";
NSString * const kTextBundleAssetsFileName = @"assets";

// UTI constants
NSString * const kUTTypeMarkdown = @"net.daringfireball.markdown";
NSString * const kUTTypeTextBundle = @"org.textbundle.package";

// Metadata constants
NSString * const kTextBundleVersion = @"version";
NSString * const kTextBundleType = @"type";
NSString * const kTextBundleTransient = @"transient";
NSString * const kTextBundleCreatorIdentifier = @"creatorIdentifier";

// Error constants
NSString * const TextBundleErrorDomain = @"TextBundleErrorDomain";

@implementation TextBundleWrapper

+ (BOOL)isTextBundleType:(NSString *)typeName
{
    return UTTypeConformsTo((__bridge CFStringRef)typeName, (__bridge CFStringRef)kUTTypeTextBundle);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Setting some default values
        self.metadata = [NSMutableDictionary dictionary];
        self.version = @(2);
        self.type = kUTTypeMarkdown;
        self.transient = @(NO);
        
        self.assetsFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
        self.assetsFileWrapper.preferredFilename = kTextBundleAssetsFileName;
    }
    
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url options:(NSFileWrapperReadingOptions)options error:(NSError **)error
{
    self = [self init];
    if (self) {
        
        BOOL success = [self readFromURL:url options:options error:error];
        if (!success) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)error
{
    self = [self init];
    if (self) {
        
        BOOL success = [self readFromFilewrapper:fileWrapper error:error];
        if (!success) {
            return nil;
        }
    }
    return self;
}


#pragma mark - Writing

- (NSFileWrapper *)fileWrapper
{
    if (!self.text) {
        return nil;
    }
    
    NSFileWrapper *textBundleFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    
    // Text
    [textBundleFileWrapper addRegularFileWithContents:[self.text dataUsingEncoding:NSUTF8StringEncoding] preferredFilename:[self textFilenameForType:self.type]];
    
    // Info
    [textBundleFileWrapper addRegularFileWithContents:[self jsonDataForMetadata:self.metadata] preferredFilename:kTextBundleInfoFileName];
    
    // Assets
    if (self.assetsFileWrapper && self.assetsFileWrapper.fileWrappers.count) {
        [textBundleFileWrapper addFileWrapper:self.assetsFileWrapper];
    }

    return textBundleFileWrapper;
}

- (BOOL)writeToURL:(NSURL *)url options:(NSFileWrapperWritingOptions)options originalContentsURL:(nullable NSURL *)originalContentsURL error:(NSError **)error
{
    return [self.fileWrapper writeToURL:url options:options originalContentsURL:originalContentsURL error:error];
}

#pragma mark - Reading

- (BOOL)readFromURL:(NSURL *)url options:(NSFileWrapperReadingOptions)options error:(NSError **)error
{
    NSError *readError = nil;
    NSFileWrapper *textBundleFileWrapper = [[NSFileWrapper alloc] initWithURL:url options:options error:&readError];
    
    if (readError) {
        if (error) { *error = readError; }
        return NO;
    }
    
    return [self readFromFilewrapper:textBundleFileWrapper error:error];
}

- (BOOL)readFromFilewrapper:(NSFileWrapper *)textBundleFileWrapper error:(NSError **)error
{
    // Info
    NSFileWrapper *infoFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:kTextBundleInfoFileName];
    if (infoFileWrapper) {
        NSData *fileData = [infoFileWrapper regularFileContents];
        NSError *jsonReadError = nil;
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&jsonReadError];
        
        if (jsonReadError) {
            if (error) { *error = jsonReadError; }
            return NO;
        }
        
        self.metadata          = [jsonObject mutableCopy];
        self.version           = self.metadata[kTextBundleVersion];
        self.type              = self.metadata[kTextBundleType];
        self.transient         = self.metadata[kTextBundleTransient];
        self.creatorIdentifier = self.metadata[kTextBundleCreatorIdentifier];
        
        [self.metadata removeObjectForKey:kTextBundleVersion];
        [self.metadata removeObjectForKey:kTextBundleType];
        [self.metadata removeObjectForKey:kTextBundleTransient];
        [self.metadata removeObjectForKey:kTextBundleCreatorIdentifier];
    }
    else {
        if (error) {
            *error = [NSError errorWithDomain:TextBundleErrorDomain code:TextBundleErrorInvalidFormat userInfo:nil];
        }

        return NO;
    }
    
    // Text
    NSFileWrapper *textFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:[self textFileNameInFileWrapper:textBundleFileWrapper]];
    if (textFileWrapper) {
        self.text = [[NSString alloc] initWithData:textFileWrapper.regularFileContents encoding:NSUTF8StringEncoding];
    }
    else {
        if (error) {
            *error = [NSError errorWithDomain:TextBundleErrorDomain code:TextBundleErrorInvalidFormat userInfo:nil];
        }
        
        return NO;
    }
    
    // Assets
    NSFileWrapper *assetsWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:kTextBundleAssetsFileName];
    if (assetsWrapper) {
        self.assetsFileWrapper = assetsWrapper;
    }
    
    return YES;
}

#pragma mark - Text

- (NSString *)textFileNameInFileWrapper:(NSFileWrapper*)fileWrapper
{
    // Finding the text.* file inside the .textbundle
    __block NSString *filename = nil;
    [[fileWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSFileWrapper * obj, BOOL *stop)
    {
        if([[obj.filename lowercaseString] hasPrefix:@"text"]) {
            filename = obj.filename;
        }
    }];

    return filename;
}

- (NSString *)textFilenameForType:(NSString *)type
{
    NSString *ext = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type, kUTTagClassFilenameExtension);
    return [@"text" stringByAppendingPathExtension:ext];
}


#pragma mark - Assets

- (NSFileWrapper *)fileWrapperForAssetFilename:(NSString *)filename
{
    __block NSFileWrapper *fileWrapper = nil;
    [[self.assetsFileWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSFileWrapper * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.filename isEqualToString:filename] || [obj.preferredFilename isEqualToString:filename]) {
            fileWrapper = obj;
        }
    }];
    
    return fileWrapper;
}

- (NSString *)addAssetFileWrapper:(NSFileWrapper *)assetFileWrapper
{
    NSString *originalFilename = assetFileWrapper.filename ?: assetFileWrapper.preferredFilename;
    NSString *filename = originalFilename;
    NSUInteger filenameCount = 1;
    BOOL shouldAddFileWrapper = YES;

    NSArray *currentFilenames = [self.assetsFileWrapper.fileWrappers allKeys];
    while ([currentFilenames containsObject:filename]) {
        NSFileWrapper *existingFileWrapper = [self.assetsFileWrapper fileWrappers][filename];
        
        // Same filename and same data, we can skip adding this file
        if ([assetFileWrapper.regularFileContents isEqualToData:existingFileWrapper.regularFileContents]) {
            shouldAddFileWrapper = NO;
            break;
        }
        
        // Same filename, different data, changing the name
        else {
            filenameCount++;
            filename = [self filenameWithIncreasedNumberCountForFilename:originalFilename currentCount:filenameCount];
            assetFileWrapper.filename = filename;
            assetFileWrapper.preferredFilename = filename;
        }

    }

    if (shouldAddFileWrapper) {
        filename = [self.assetsFileWrapper addFileWrapper:assetFileWrapper];
    }
    
    return filename;
}


#pragma mark - Metadata

- (NSData *)jsonDataForMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *allMetadata = [NSMutableDictionary dictionary];
    [allMetadata addEntriesFromDictionary:metadata];
    
    if (self.version != nil)           { allMetadata[kTextBundleVersion] = self.version;                     }
    if (self.type != nil)              { allMetadata[kTextBundleType] = self.type;                           }
    if (self.transient != nil)         { allMetadata[kTextBundleTransient] = self.transient;                 }
    if (self.creatorIdentifier != nil) { allMetadata[kTextBundleCreatorIdentifier] = self.creatorIdentifier; }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allMetadata
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    return jsonData;
}

#pragma mark - String Utils

- (NSString *)filenameWithIncreasedNumberCountForFilename:(NSString *)filename currentCount:(NSInteger)currentCount
{
    NSString* pathNoExt = [filename stringByDeletingPathExtension];
    NSString* extension = [filename pathExtension];
    
    NSString *newFilename = [NSString stringWithFormat:@"%@ %ld", pathNoExt, (long)currentCount];
    if (extension && ![extension isEqualToString:@""])
    {
        newFilename = [newFilename stringByAppendingPathExtension:extension];
    }
    
    return newFilename;
}


@end

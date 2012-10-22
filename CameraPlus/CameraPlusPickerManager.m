//
//  CameraPlusPickerHelper.m
//  PickerAPITester
//
//  Created by Karl von Randow on 28/08/11.
//  Copyright 2011 XK72 Ltd. All rights reserved.
//

#import "CameraPlusPickerManager.h"

#import <MobileCoreServices/UTCoreTypes.h>

NSString *CameraPlusPasteboardsName = @"com.taptaptap.CameraPlus.PasteboardsNames";
NSString *CameraPlusExportPhotoMetadataType = @"com.taptaptap.CameraPlus.photoMetadata";

@interface CameraPlusPickerManager ()

- (void)deletePreviousPasteboards;

@end

@implementation CameraPlusPickerManager

@synthesize callbackURLProtocol;
@synthesize maxImages;
@synthesize mode;
@synthesize imageSize;

+ (CameraPlusPickerManager*)sharedManager {
    static CameraPlusPickerManager *manager;
    if (!manager) {
        manager = [[CameraPlusPickerManager alloc] init];
    }
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.maxImages = 1;
        self.mode = CameraPlusPickerModeShootAndLightbox;
        self.imageSize = 0;
        
        [self deletePreviousPasteboards];
    }
    
    return self;
}


#pragma mark - Camera+ availability

- (BOOL)cameraPlusPickerAvailable {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cameraplus-picker://"]];
}

- (BOOL)cameraPlusAvailable {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"camplus://"]];
}

#pragma mark - Public utilities

+ (NSDictionary*)imagePickerControllerInfoDictionaryForImage:(UIImage*)image metadata:(NSDictionary*)metadata {
    if (![metadata count])
        metadata = nil;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:(id)kUTTypeImage, UIImagePickerControllerMediaType, 
            image, UIImagePickerControllerOriginalImage,
            [NSValue valueWithCGRect:CGRectMake(0, 0, image.size.width, image.size.height)], UIImagePickerControllerCropRect,
            metadata, UIImagePickerControllerMediaMetadata,
            nil];
}

#pragma mark - Utilities

- (NSString*)modeStringForMode:(CameraPlusPickerMode)aMode {
    switch (aMode) {
        case CameraPlusPickerModeShootAndLightbox:
            return @"all";
        case CameraPlusPickerModeShootOnly:
            return @"takephoto";
        case CameraPlusPickerModeLightboxOnly:
            return @"lightbox";
        case CameraPlusPickerModeEdit:
            return @"edit";
        default:
            NSLog(@"Unsupported CameraPlusPickerMode: %i", aMode);
            return @"all";
    }
}

- (CameraPlusPickerMode)modeForModeString:(NSString*)str {
    if ([@"all" isEqualToString:str]) {
        return CameraPlusPickerModeShootAndLightbox;
    } else if ([@"takephoto" isEqualToString:str]) {
        return CameraPlusPickerModeShootOnly;
    } else if ([@"lightbox" isEqualToString:str]) {
        return CameraPlusPickerModeLightboxOnly;
    } else if ([@"edit" isEqualToString:str]) {
        return CameraPlusPickerModeEdit;
    } else {
        NSLog(@"Unsupported CameraPlusPickerMode: %@", str);
        return CameraPlusPickerModeShootAndLightbox;
    }
}

- (void)rememberPasteboardForDeletion:(UIPasteboard *)pasteboard {
    /* Remember pasteboard to delete later */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *existingPasteboards = [defaults objectForKey:CameraPlusPasteboardsName];
    if (existingPasteboards) {
        NSMutableArray *newPasteboards = [NSMutableArray arrayWithArray:existingPasteboards];
        [newPasteboards addObject:pasteboard.name];
        [defaults setObject:newPasteboards forKey:CameraPlusPasteboardsName];
    } else {
        [defaults setObject:[NSArray arrayWithObject:pasteboard.name] forKey:CameraPlusPasteboardsName];
    }
    [defaults synchronize];
}

- (void)deletePreviousPasteboards {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *pasteboardNames = [defaults objectForKey:CameraPlusPasteboardsName];
    for (NSString *name in pasteboardNames) {
        [UIPasteboard removePasteboardWithName:name];
    }
    
    [defaults removeObjectForKey:CameraPlusPasteboardsName];
    [defaults synchronize];
}

#pragma mark Open Camera+ picker

- (BOOL)openCameraPlusPickerWithMode:(CameraPlusPickerMode)aMode withImageData:(NSData*)imageData {
    if ([self cameraPlusPickerAvailable]) {
        if (self.callbackURLProtocol) {
            NSMutableString *urlString = [NSMutableString stringWithFormat:@"cameraplus-picker://picker?v=1&callback=%@&mode=%@&maxImages=%i&imageSize=%i", 
                                          [self.callbackURLProtocol stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], 
                                          [self modeStringForMode:aMode],
                                          self.maxImages,
                                          self.imageSize];
            if (imageData) {
                UIPasteboard *pasteboard = [UIPasteboard pasteboardWithUniqueName];
                pasteboard.persistent = YES;
                
                [pasteboard setData:imageData forPasteboardType:(id)kUTTypeJPEG];
                [self rememberPasteboardForDeletion:pasteboard];
                
                [urlString appendFormat:@"&pasteboard=%@", pasteboard.name];
            }
            NSURL *url = [NSURL URLWithString:urlString];
            [[UIApplication sharedApplication] openURL:url];
            return YES;
        } else {
            NSLog(@"CameraPlusPickerManager.callbackURLProtocol not set");
            return NO;
        }
    } else {
        NSLog(@"CameraPlusPickerManager: Camera+ picker not found on this device");
        return NO;
    }
}

- (BOOL)openCameraPlusPicker {
    return [self openCameraPlusPickerWithMode:self.mode withImageData:nil];
}

- (BOOL)openCameraPlusPickerWithMode:(CameraPlusPickerMode)aMode {
    return [self openCameraPlusPickerWithMode:aMode withImageData:nil];
}

- (BOOL)openCameraPlusEditorWithImage:(UIImage*)image {
    return [self openCameraPlusPickerWithMode:CameraPlusPickerModeEdit
                                withImageData:UIImageJPEGRepresentation(image, 0.9)];
}

- (BOOL)openCameraPlusEditorWithImageData:(NSData*)imageData {
    return [self openCameraPlusPickerWithMode:CameraPlusPickerModeEdit withImageData:imageData];
}

#pragma mark Query string parsing

- (NSMutableDictionary *)queryStringToDictionary:(NSString *)queryString {
    if (!queryString)
        return nil;
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSRange separator = [pair rangeOfString:@"="];
        NSString *key, *value;
        if (separator.location != NSNotFound) {
            key = [pair substringToIndex:separator.location];
            value = [[pair substringFromIndex:separator.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            key = pair;
            value = @"";
        }
        
        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [result setObject:value forKey:key];
    }
    
    return result;
}

#pragma mark Callbacks

- (BOOL)shouldHandleURLAsCameraPlusPickerCallback:(NSURL*)url {
    return [[url host] isEqualToString:@"cameraplus-picker"];
}

- (void)handleCameraPlusPickerCallback:(NSURL*)url delegate:(id<CameraPlusPickerManagerDelegate>)delegate {
#if NS_BLOCKS_AVAILABLE
    [self handleCameraPlusPickerCallback:url 
                            usingBlock:^(CameraPlusPickedImages *images) {
                                [delegate cameraPlusPickerManager:self
                                                    didPickImages:images];
                             }
                             cancelBlock:^() {
                                 [delegate cameraPlusPickerManagerDidCancel:self];
                             }
     ];
}


- (void)handleCameraPlusPickerCallback:(NSURL*)url 
                            usingBlock:(CameraPlusPickerCompletionBlock)block
                           cancelBlock:(CameraPlusPickerCancelBlock)cancelBlock {
#endif
    [self deletePreviousPasteboards];
    
    NSDictionary *data = [self queryStringToDictionary:[url query]];
    if (data) {
        self.mode = [self modeForModeString:[data objectForKey:@"mode"]];
        NSString *pasteboardName = [data objectForKey:@"pasteboard"];
        
        UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:pasteboardName create:NO];
        if (pasteboard) {
            CameraPlusPickedImages *images = [[CameraPlusPickedImages alloc] initWithPasteboard:pasteboard];
#if NS_BLOCKS_AVAILABLE
            if (block) {
                block(images);
            }
#else
            [delegate cameraPlusPickerManager:self didPickImages:images];
#endif
            
            [UIPasteboard removePasteboardWithName:pasteboardName];
        } else {
#if NS_BLOCKS_AVAILABLE
            if (cancelBlock != NULL) {
                cancelBlock();
            }
#else
            if ([delegate respondsToSelector:@selector(cameraPlusPickerManagerDidCancel:)]) {
                [delegate cameraPlusPickerManagerDidCancel:self];
            }
#endif
        }
    }
}

@end


@implementation CameraPlusPickedImages

- (id)initWithPasteboard:(UIPasteboard *)aPasteboard {
    if ((self = [super init])) {
        pasteboard = aPasteboard;
    }
    return self;
}


- (int)numberOfImages {
    return pasteboard.numberOfItems;
}

- (UIImage *)imageAtIndex:(NSUInteger)i {
    return [UIImage imageWithData:[self imageDataAtIndex:i]];
}

- (NSData *)imageDataAtIndex:(NSUInteger)i {
    NSArray *array = [pasteboard dataForPasteboardType:(id)kUTTypeJPEG
                                             inItemSet:[NSIndexSet indexSetWithIndex:i]];
    if (array.count) {
        return [array objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSDictionary *)metadataAtIndex:(NSUInteger)i {
    NSArray *array = [pasteboard dataForPasteboardType:CameraPlusExportPhotoMetadataType
                                             inItemSet:[NSIndexSet indexSetWithIndex:i]];
    if (array.count) {
        return [array objectAtIndex:0];
    } else {
        return nil;
    }
}

- (UIImage *)image {
    return [self imageAtIndex:0];
}

- (NSArray *)images {
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < self.numberOfImages; i++) {
        UIImage *image = [self imageAtIndex:i];
        if (image) {
            [result addObject:image];
        }
    }
    return result;
}

@end

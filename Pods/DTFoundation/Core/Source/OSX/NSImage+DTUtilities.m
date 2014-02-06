//
//  NSImage+DTUtilities.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSImage+DTUtilities.h"

@implementation NSImage (DTUtilities)

- (BOOL)writeJPEGToFile:(NSString *)path withCompressionFactor:(CGFloat)compressionFactor atomically:(BOOL)useAuxiliaryFile
{
	NSData *imageData = [self TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressionFactor] forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	return [imageData writeToFile:path atomically:useAuxiliaryFile];
}

@end

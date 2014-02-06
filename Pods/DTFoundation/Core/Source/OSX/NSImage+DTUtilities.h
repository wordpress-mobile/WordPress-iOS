//
//  NSImage+DTUtilities.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Utilities for `NSImage`.
 */
@interface NSImage (DTUtilities)

/**-------------------------------------------------------------------------------------
 @name Saving to Disk
 ---------------------------------------------------------------------------------------
 */

/**
 Encodes the receiver to JPEG using the given compression Factor
 @param path The file path to write to
 @param compressionFactor The compression factor between 0.0 and 1.0
 @param useAuxiliaryFile If `YES` then the writing is atomically
 @returns `YES` if the writing to disk was successful
 */
- (BOOL)writeJPEGToFile:(NSString *)path withCompressionFactor:(CGFloat)compressionFactor atomically:(BOOL)useAuxiliaryFile;

@end

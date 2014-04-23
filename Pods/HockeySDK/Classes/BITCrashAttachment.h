/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2014 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

/**
 *  Provides support to add binary attachments to crash reports
 *
 *  This is used by `[BITCrashManagerDelegate attachmentForCrashManager:]`
 */
@interface BITCrashAttachment : NSObject<NSCoding>

/**
 *  The filename the attachment should get
 */
@property (nonatomic, readonly, strong) NSString *filename;

/**
 *  The attachment data as NSData object
 */
@property (nonatomic, readonly, strong) NSData *attachmentData;

/**
 *  The content type of your data as MIME type
 */
@property (nonatomic, readonly, strong) NSString *contentType;

/**
 *  Create an BITCrashAttachment instance with a given filename and NSData object
 *
 *  @param filename       The filename the attachment should get
 *  @param attachmentData The attachment data as NSData
 *  @param contentType    The content type of your data as MIME type
 *
 *  @return An instsance of BITCrashAttachment
 */
- (instancetype)initWithFilename:(NSString *)filename
                  attachmentData:(NSData *)attachmentData
                     contentType:(NSString *)contentType;

@end

/*
 *
 * Modified BSD license.
 *
 * Based on source code copyright (c) 2010-2012 Florent Pillet,
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Any redistribution is done solely for personal benefit and not for any
 *    commercial purpose or for monetary gain
 *
 * 4. No binary form of source code is submitted to App Store℠ of Apple Inc.
 *
 * 5. Neither the name of the Sung-Taek, Kim nor the names of its contributors
 *    may be used to endorse or promote products derived from  this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER AND AND CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>


// Logger Message Cell Constants
#define MAX_DATA_LINES					16		// max number of data lines to show

#define MINIMUM_CELL_HEIGHT				30.0f
#define INDENTATION_TAB_WIDTH			10.0f	// in pixels

#define TIMESTAMP_COLUMN_WIDTH			85.0f
#define	DEFAULT_THREAD_COLUMN_WIDTH		85.f

#define MSG_CELL_PORTRAIT_WIDTH			768.f
#define MSG_CELL_PORTRAIT_MAX_HEIGHT	1004.f

#define MSG_CELL_LANDSCAPE_WDITH		1024.f
#define MSG_CELL_LANDSCALE_MAX_HEIGHT	748.f

#define MSG_CELL_TOP_PADDING			2.f
#define MSG_CELL_TOP_BOTTOM_PADDING		(MSG_CELL_TOP_PADDING + MSG_CELL_TOP_PADDING)

#define MSG_CELL_LEFT_PADDING			4.f
#define MSG_CELL_SIDE_PADDING			(MSG_CELL_LEFT_PADDING + MSG_CELL_LEFT_PADDING)

#define MSG_TRUNCATE_THREADHOLD_LENGTH	2048

#define VIEWCONTROLLER_TITLE_HEIGHT		79.f

extern NSString * const kBottomHintText;
extern NSString * const kBottomHintData;

extern NSString * const kDefaultFontName;
#define DEFAULT_FONT_SIZE				12.f

extern NSString * const kTagAndLevelFontName;
#define DEFAULT_TAG_LEVEL_SIZE			11.f

extern NSString * const kMonospacedFontName;
#define DEFAULT_MONOSPACED_SIZE			12.f

extern NSString * const kMessageAttributesChangedNotification;
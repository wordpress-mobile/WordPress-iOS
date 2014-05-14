/*
 * Diff Match and Patch
 *
 * Copyright 2011 geheimwerk.de.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: fraser@google.com (Neil Fraser)
 * ObjC port: jan@geheimwerk.de (Jan Weiß)
 */

#import <Foundation/Foundation.h>

#import <DiffMatchPatch/DiffMatchPatch.h>
#import "TestUtilities.h"


typedef enum {
  DiffDefaultMode = 1,
  DiffLineMode = 2,
  DiffWordMode = 3,
  DiffParagraphMode = 4,
  DiffSentenceMode = 5,
  DiffLineBreakDelimiteredMode = 6
} DiffMode;


NSMutableArray * diff_defaultMode(NSString *text1, NSString *text2);
NSMutableArray * diff_withMode(NSString *text1, NSString *text2, DiffMode mode);

NSMutableArray * diff_withMode(NSString *text1, NSString *text2, DiffMode mode) {
  DiffMatchPatch *dmp = [DiffMatchPatch new];
  
  DiffTokenMode tokenMode = 0;
  
  switch (mode) {
    case DiffDefaultMode:
      tokenMode = 0;
      break;
    case DiffLineMode:
      tokenMode = -1;
      break;
    case DiffWordMode:
      tokenMode = DiffWordTokens;
      break;
    case DiffParagraphMode:
      tokenMode = DiffParagraphTokens;
      break;
    case DiffSentenceMode:
      tokenMode = DiffSentenceTokens;
      break;
    case DiffLineBreakDelimiteredMode:
      tokenMode = DiffLineBreakDelimiteredTokens;
      break;
    default:
      tokenMode = 0;
      break;
  }
  
  NSMutableArray *tokenArray;
  if (tokenMode != 0) {
    NSArray *a;
    if (mode == DiffLineMode) {
      a = [dmp diff_linesToCharsForFirstString:text1 andSecondString:text2];
    }
    else {
      a = [dmp diff_tokensToCharsForFirstString:text1 andSecondString:text2 mode:tokenMode];
    }
    
    NSString *tokenText1 = [a objectAtIndex:0];
    NSString *tokenText2 = [a objectAtIndex:1];
    tokenArray = [a objectAtIndex:2];
    
    text1 = tokenText1;
    text2 = tokenText2;
  }
  
  dmp.Diff_Timeout = 0;
  NSMutableArray *diffs = [dmp diff_mainOfOldString:text1 andNewString:text2 checkLines:NO];
  
  if (tokenMode != 0) {
    [dmp diff_chars:diffs toLines:tokenArray];
  }
  
  [dmp release];
  
  return diffs;
}

NSMutableArray * diff_defaultMode(NSString *text1, NSString *text2) {
  DiffMatchPatch *dmp = [[DiffMatchPatch new] autorelease];
  
  dmp.Diff_Timeout = 0;
  NSMutableArray *diffs = [dmp diff_mainOfOldString:text1 andNewString:text2 checkLines:NO];
  
  return diffs;
}


int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  NSArray *cliArguments = [[NSProcessInfo processInfo] arguments];
  
  if ([cliArguments count] < 3) {
    fprintf(stderr, "usage: %s <txt1> <txt2> [default|line|word|paragraph|sentence|line-break-delimitered]\n",
            [[[NSProcessInfo processInfo] processName] UTF8String]);
    [pool drain];
    return EXIT_FAILURE;
  }

  NSString *text1 = diff_stringForFilePath([cliArguments objectAtIndex:1]);
  NSString *text2 = diff_stringForFilePath([cliArguments objectAtIndex:2]);
  
  if (text1 == nil || text2 == nil) {
    return EXIT_FAILURE;
  }
  
  NSMutableArray *diffs;
  DiffMode mode = DiffDefaultMode;
  
  if ([cliArguments count] >= 4) {
    NSString *modeString = [cliArguments objectAtIndex:3];
    
    if ([modeString isEqualToString:@"line"]) {
      mode = DiffLineMode;
    }
    else if ([modeString isEqualToString:@"word"]) {
      mode = DiffWordMode;
    }
    else if ([modeString isEqualToString:@"paragraph"]) {
      mode = DiffParagraphMode;
    }
    else if ([modeString isEqualToString:@"sentence"]) {
      mode = DiffSentenceMode;
    }
    else if ([modeString isEqualToString:@"line-break-delimitered"]) {
      mode = DiffLineBreakDelimiteredMode;
    }
  }
  
  diffs = diff_withMode(text1, text2, mode);
  
  NSLog(@"%@", [diffs description]);
  
  [pool drain];
  return EXIT_SUCCESS;
}

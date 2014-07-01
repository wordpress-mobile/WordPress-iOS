/*
 * Diff Match and Patch
 *
 * Copyright 2010 geheimwerk.de.
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

#include <CoreFoundation/CoreFoundation.h>

#include "DiffMatchPatchCFUtilities.h"

#include "MinMaxMacros.h"
#include <regex.h>
#include <limits.h>
#include <AssertMacros.h>

Boolean diff_regExMatch(CFStringRef text, const regex_t *re);

CFArrayRef diff_halfMatchICreate(CFStringRef longtext, CFStringRef shorttext, CFIndex i);

void diff_mungeHelper(CFStringRef token, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash, CFMutableStringRef chars);

// Utility functions
CFStringRef diff_CFStringCreateFromUnichar(UniChar ch) {
  CFStringRef c = CFStringCreateWithCharacters(kCFAllocatorDefault, &ch, 1);
  return c;
}

Boolean diff_regExMatch(CFStringRef text, const regex_t *re) {
  //TODO(jan): Using regex.h is far from optimal. Find an alternative.
  Boolean isMatch;
  const char *bytes;
  char *localBuffer = NULL;
  char *textCString = NULL;
  // We are only interested in line endings anyway so ASCII is fine.
  CFStringEncoding encoding = kCFStringEncodingASCII;

  bytes = CFStringGetCStringPtr(text, encoding);

  if (bytes == NULL) {
    Boolean success;
    CFIndex length;
    CFIndex usedBufferLength;
    CFIndex textLength = CFStringGetLength(text);
    CFRange rangeToProcess = CFRangeMake(0, textLength);

    success = (CFStringGetBytes(text, rangeToProcess, encoding, '?', false, NULL, LONG_MAX, &usedBufferLength) > 0);
    if (success) {
      length = usedBufferLength + 1;

      localBuffer = calloc(length, sizeof(char));
      success = (CFStringGetBytes(text, rangeToProcess, encoding, '?', false, (UInt8 *)localBuffer, length, NULL) > 0);

      if (success) {
        textCString = localBuffer;
      }
    }
  } else {
    textCString = (char *)bytes;
  }

  if (textCString != NULL) {
    isMatch = (regexec(re, textCString, 0, NULL, 0) == 0);
  } else {
    isMatch = false;
    //check(0);
  }

  if (localBuffer != NULL) {
    free(localBuffer);
  }

  return isMatch;
}


/**
 * Determine the common prefix of two strings.
 * @param text1 First string.
 * @param text2 Second string.
 * @return The number of characters common to the start of each string.
 */
CFIndex diff_commonPrefix(CFStringRef text1, CFStringRef text2) {
  // Performance analysis: http://neil.fraser.name/news/2007/10/09/
  CFIndex text1_length = CFStringGetLength(text1);
  CFIndex text2_length = CFStringGetLength(text2);

  CFStringInlineBuffer text1_inlineBuffer, text2_inlineBuffer;
  CFStringInitInlineBuffer(text1, &text1_inlineBuffer, CFRangeMake(0, text1_length));
  CFStringInitInlineBuffer(text2, &text2_inlineBuffer, CFRangeMake(0, text2_length));

  UniChar char1, char2;
  CFIndex n = MIN(text1_length, text2_length);

  for (CFIndex i = 0; i < n; i++) {
    char1 = CFStringGetCharacterFromInlineBuffer(&text1_inlineBuffer, i);
    char2 = CFStringGetCharacterFromInlineBuffer(&text2_inlineBuffer, i);

    if (char1 != char2) {
      return i;
    }
  }

  return n;
}

/**
 * Determine the common suffix of two strings.
 * @param text1 First string.
 * @param text2 Second string.
 * @return The number of characters common to the end of each string.
 */
CFIndex diff_commonSuffix(CFStringRef text1, CFStringRef text2) {
  // Performance analysis: http://neil.fraser.name/news/2007/10/09/
  CFIndex text1_length = CFStringGetLength(text1);
  CFIndex text2_length = CFStringGetLength(text2);

  CFStringInlineBuffer text1_inlineBuffer, text2_inlineBuffer;
  CFStringInitInlineBuffer(text1, &text1_inlineBuffer, CFRangeMake(0, text1_length));
  CFStringInitInlineBuffer(text2, &text2_inlineBuffer, CFRangeMake(0, text2_length));

  UniChar char1, char2;
  CFIndex n = MIN(text1_length, text2_length);

  for (CFIndex i = 1; i <= n; i++) {
    char1 = CFStringGetCharacterFromInlineBuffer(&text1_inlineBuffer, (text1_length - i));
    char2 = CFStringGetCharacterFromInlineBuffer(&text2_inlineBuffer, (text2_length - i));

    if (char1 != char2) {
      return i - 1;
    }
  }
  return n;
}

/**
 * Determine if the suffix of one CFStringRef is the prefix of another.
 * @param text1 First CFStringRef.
 * @param text2 Second CFStringRef.
 * @return The number of characters common to the end of the first
 *     CFStringRef and the start of the second CFStringRef.
 */
CFIndex diff_commonOverlap(CFStringRef text1, CFStringRef text2) {
  CFIndex common_overlap = 0;

  // Cache the text lengths to prevent multiple calls.
  CFIndex text1_length = CFStringGetLength(text1);
  CFIndex text2_length = CFStringGetLength(text2);

  // Eliminate the nil case.
  if (text1_length == 0 || text2_length == 0) {
    return 0;
  }

  // Truncate the longer CFStringRef.
  CFStringRef text1_trunc;
  CFStringRef text2_trunc;
  CFIndex text1_trunc_length;
  if (text1_length > text2_length) {
    text1_trunc_length = text2_length;
    text1_trunc = diff_CFStringCreateRightSubstring(text1, text1_length, text1_trunc_length);

    text2_trunc = CFRetain(text2);
  } else if (text1_length < text2_length) {
    text1_trunc_length = text1_length;
    text1_trunc = CFRetain(text1);

    CFIndex text2_trunc_length = text1_length;
    text2_trunc = diff_CFStringCreateLeftSubstring(text2, text2_trunc_length);
  } else {
    text1_trunc_length = text1_length;
    text1_trunc = CFRetain(text1);

    text2_trunc = CFRetain(text2);
  }

  CFIndex text_length = MIN(text1_length, text2_length);
  // Quick check for the worst case.
  if (CFStringCompare(text1_trunc, text2_trunc, 0) == kCFCompareEqualTo) {
    common_overlap = text_length;
  } else {
    // Start by looking for a single character match
    // and increase length until no match is found.
    // Performance analysis: http://neil.fraser.name/news/2010/11/04/
    CFIndex best = 0;
    CFIndex length = 1;
    while (true) {
      CFStringRef pattern = diff_CFStringCreateRightSubstring(text1_trunc, text1_trunc_length, length);
      CFRange foundRange = CFStringFind(text2_trunc, pattern, 0);
      CFRelease(pattern);

      CFIndex found =  foundRange.location;
      if (found == kCFNotFound) {
        common_overlap = best;
        break;
      }
      length += found;

      CFStringRef text1_sub = diff_CFStringCreateRightSubstring(text1_trunc, text1_trunc_length, length);
      CFStringRef text2_sub = diff_CFStringCreateLeftSubstring(text2_trunc, length);

      if (found == 0 || (CFStringCompare(text1_sub, text2_sub, 0) == kCFCompareEqualTo)) {
        best = length;
        length++;
      }

      CFRelease(text1_sub);
      CFRelease(text2_sub);
    }
  }

  CFRelease(text1_trunc);
  CFRelease(text2_trunc);
  return common_overlap;
}

/**
 * Do the two texts share a Substring which is at least half the length of
 * the longer text?
 * This speedup can produce non-minimal diffs.
 * @param text1 First CFStringRef.
 * @param text2 Second CFStringRef.
 * @param diffTimeout Time limit for diff.
 * @return Five element CFStringRef array, containing the prefix of text1, the
 *     suffix of text1, the prefix of text2, the suffix of text2 and the
 *     common middle.   Or NULL if there was no match.
 */
CFArrayRef diff_halfMatchCreate(CFStringRef text1, CFStringRef text2, const float diffTimeout) {
  if (diffTimeout <= 0) {
    // Don't risk returning a non-optimal diff if we have unlimited time.
    return NULL;
  }
  CFStringRef longtext = CFStringGetLength(text1) > CFStringGetLength(text2) ? text1 : text2;
  CFStringRef shorttext = CFStringGetLength(text1) > CFStringGetLength(text2) ? text2 : text1;
  if (CFStringGetLength(longtext) < 4 || CFStringGetLength(shorttext) * 2 < CFStringGetLength(longtext)) {
    return NULL;  // Pointless.
  }

  // First check if the second quarter is the seed for a half-match.
  CFArrayRef hm1 = diff_halfMatchICreate(longtext, shorttext,
                       (CFStringGetLength(longtext) + 3) / 4);
  // Check again based on the third quarter.
  CFArrayRef hm2 = diff_halfMatchICreate(longtext, shorttext,
                       (CFStringGetLength(longtext) + 1) / 2);
  CFArrayRef hm;
  if (hm1 == NULL && hm2 == NULL) {
    return NULL;
  } else if (hm2 == NULL) {
    hm = CFRetain(hm1);
  } else if (hm1 == NULL) {
    hm = CFRetain(hm2);
  } else {
    // Both matched.  Select the longest.
    hm = CFStringGetLength(CFArrayGetValueAtIndex(hm1, 4)) > CFStringGetLength(CFArrayGetValueAtIndex(hm2, 4)) ? CFRetain(hm1) : CFRetain(hm2);
  }

  if (hm1 != NULL) {
    CFRelease(hm1);
  }
  if (hm2 != NULL) {
    CFRelease(hm2);
  }

  // A half-match was found, sort out the return data.
  if (CFStringGetLength(text1) > CFStringGetLength(text2)) {
    return hm;
    //return new CFStringRef[]{hm[0], hm[1], hm[2], hm[3], hm[4]};
  } else {
    //    { hm[0], hm[1], hm[2], hm[3], hm[4] }
    // => { hm[2], hm[3], hm[0], hm[1], hm[4] }

    CFMutableArrayRef hm_mutable = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(hm), hm);

    CFRelease(hm);

    CFArrayExchangeValuesAtIndices(hm_mutable, 0, 2);
    CFArrayExchangeValuesAtIndices(hm_mutable, 1, 3);
    return hm_mutable;
  }
}

/**
 * Does a Substring of shorttext exist within longtext such that the
 * Substring is at least half the length of longtext?
 * @param longtext Longer CFStringRef.
 * @param shorttext Shorter CFStringRef.
 * @param i Start index of quarter length Substring within longtext.
 * @return Five element CFStringRef array, containing the prefix of longtext, the
 *     suffix of longtext, the prefix of shorttext, the suffix of shorttext
 *     and the common middle.   Or NULL if there was no match.
 */
CFArrayRef diff_halfMatchICreate(CFStringRef longtext, CFStringRef shorttext, CFIndex i) {
  // Start with a 1/4 length Substring at position i as a seed.
  CFStringRef seed = diff_CFStringCreateSubstring(longtext, i, CFStringGetLength(longtext) / 4);
  CFIndex j = -1;
  CFStringRef best_common = CFSTR("");
  CFStringRef best_longtext_a = CFSTR(""), best_longtext_b = CFSTR("");
  CFStringRef best_shorttext_a = CFSTR(""), best_shorttext_b = CFSTR("");

  CFStringRef longtext_substring, shorttext_substring;
  CFIndex shorttext_length = CFStringGetLength(shorttext);
  CFRange resultRange;
  CFRange rangeToSearch;
  rangeToSearch.length = shorttext_length - (j + 1);
  rangeToSearch.location = j + 1;

  while (j < CFStringGetLength(shorttext)
       && (CFStringFindWithOptions(shorttext, seed, rangeToSearch, 0, &resultRange) == true)) {
    j = resultRange.location;
    rangeToSearch.length = shorttext_length - (j + 1);
    rangeToSearch.location = j + 1;

    longtext_substring = diff_CFStringCreateSubstringWithStartIndex(longtext, i);
    shorttext_substring = diff_CFStringCreateSubstringWithStartIndex(shorttext, j);

    CFIndex prefixLength = diff_commonPrefix(longtext_substring, shorttext_substring);

    CFRelease(longtext_substring);
    CFRelease(shorttext_substring);

    longtext_substring = diff_CFStringCreateLeftSubstring(longtext, i);
    shorttext_substring = diff_CFStringCreateLeftSubstring(shorttext, j);

    CFIndex suffixLength = diff_commonSuffix(longtext_substring, shorttext_substring);

    CFRelease(longtext_substring);
    CFRelease(shorttext_substring);

    if (CFStringGetLength(best_common) < suffixLength + prefixLength) {
      CFRelease(best_common);
      CFRelease(best_longtext_a);
      CFRelease(best_longtext_b);
      CFRelease(best_shorttext_a);
      CFRelease(best_shorttext_b);

      best_common = diff_CFStringCreateSubstring(shorttext, j - suffixLength, suffixLength + prefixLength);

      best_longtext_a = diff_CFStringCreateLeftSubstring(longtext, i - suffixLength);
      best_longtext_b = diff_CFStringCreateSubstringWithStartIndex(longtext, i + prefixLength);
      best_shorttext_a = diff_CFStringCreateLeftSubstring(shorttext, j - suffixLength);
      best_shorttext_b = diff_CFStringCreateSubstringWithStartIndex(shorttext, j + prefixLength);
    }
  }

  CFRelease(seed);

  CFArrayRef halfMatchIArray;
  if (CFStringGetLength(best_common) * 2 >= CFStringGetLength(longtext)) {
    const CFStringRef values[] = { best_longtext_a, best_longtext_b,
                     best_shorttext_a, best_shorttext_b, best_common };
    halfMatchIArray = CFArrayCreate(kCFAllocatorDefault, (const void **)values, (sizeof(values) / sizeof(values[0])), &kCFTypeArrayCallBacks);
  } else {
    halfMatchIArray = NULL;
  }

  CFRelease(best_common);
  CFRelease(best_longtext_a);
  CFRelease(best_longtext_b);
  CFRelease(best_shorttext_a);
  CFRelease(best_shorttext_b);

  return halfMatchIArray;
}

void diff_mungeHelper(CFStringRef token, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash, CFMutableStringRef chars) {
  #define diff_UniCharMax (~(UniChar)0x00)
  
  CFIndex hash;
  
  if (CFDictionaryGetValueIfPresent(tokenHash, token, (const void **)&hash)) {
    const UniChar hashChar = (UniChar)hash;
    CFStringAppendCharacters(chars, &hashChar, 1);
  } else {
    CFArrayAppendValue(tokenArray, token);
    hash = CFArrayGetCount(tokenArray) - 1;
    check_string(hash <= diff_UniCharMax, "Hash value has exceeded UniCharMax!");
    CFDictionaryAddValue(tokenHash, token, (void *)hash);
    const UniChar hashChar = (UniChar)hash;
    CFStringAppendCharacters(chars, &hashChar, 1);
  }
  
  #undef diff_UniCharMax
}

CF_INLINE void diff_mungeTokenForRange(CFStringRef text, CFRange tokenRange, CFMutableStringRef chars, CFMutableDictionaryRef tokenHash, CFMutableArrayRef tokenArray) {
  CFStringRef token = CFStringCreateWithSubstring(kCFAllocatorDefault, text, tokenRange);
  diff_mungeHelper(token, tokenArray, tokenHash, chars);
  CFRelease(token);
}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where each Unicode character represents one line.
 * @param text CFString to encode.
 * @param lineArray CFMutableArray of unique strings.
 * @param lineHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_linesToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef lineArray, CFMutableDictionaryRef lineHash) {
  #define lineStart lineStartRange.location
  #define lineEnd lineEndRange.location

  CFRange lineStartRange;
  CFRange lineEndRange;
  lineStart = 0;
  lineEnd = -1;
  CFStringRef line;
  CFMutableStringRef chars = CFStringCreateMutable(kCFAllocatorDefault, 0);

  CFIndex textLength = CFStringGetLength(text);

  // Walk the text, pulling out a Substring for each line.
  // CFStringCreateArrayBySeparatingStrings(kCFAllocatorDefault, text, CFSTR("\n")) would temporarily double our memory footprint.
  // Modifying text would create many large strings.
  while (lineEnd < textLength - 1) {
    lineStartRange.length = textLength - lineStart;

    if (CFStringFindWithOptions(text, CFSTR("\n"), lineStartRange, 0, &lineEndRange) == false) {
      lineEnd = textLength - 1;
    } /* else {
      lineEnd = lineEndRange.location;
    }*/

    line = diff_CFStringCreateJavaSubstring(text, lineStart, lineEnd + 1);
    lineStart = lineEnd + 1;

    diff_mungeHelper(line, lineArray, lineHash, chars);

    CFRelease(line);
  }
  
  return chars;

  #undef diff_UniCharMax
  #undef lineStart
  #undef lineEnd
}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where where each Unicode character represents one token (or boundary between tokens).
 * @param text CFString to encode.
 * @param tokenArray CFMutableArray of unique strings.
 * @param tokenHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_tokensToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash, CFOptionFlags tokenizerOptions) {
  
  CFMutableStringRef chars = CFStringCreateMutable(kCFAllocatorDefault, 0);
  
  CFIndex textLength = CFStringGetLength(text);
  
  //CFLocaleRef currentLocale = CFLocaleCopyCurrent();
  
  CFRange tokenizerRange = CFRangeMake(0, textLength);
  
  CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, text, tokenizerRange, tokenizerOptions, NULL);
  
  //CFRelease(currentLocale);
  
  // Set tokenizer to the start of the string. 
  CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0);
  
  // Walk the text, pulling out a substring for each token (or boundary between tokens). 
  // A token is either a word, sentence, paragraph or line depending on what tokenizerOptions is set to. 
  CFRange tokenRange;
  CFIndex prevTokenRangeMax = 0;
  while (tokenType != kCFStringTokenizerTokenNone) {
    tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
    
    if (tokenRange.location > prevTokenRangeMax) {
      // This probably is a bug in the tokenizer: for some reason, gaps in the tokenization can appear. 
      // One particular example is the tokenizer skipping a line feed ('\n') directly after a string of Chinese characters
      CFRange gapRange = CFRangeMake(prevTokenRangeMax, (tokenRange.location - prevTokenRangeMax));
      diff_mungeTokenForRange(text, gapRange, chars, tokenHash, tokenArray);
    }
    
    diff_mungeTokenForRange(text, tokenRange, chars, tokenHash, tokenArray);
    
    tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);
    
    prevTokenRangeMax = (tokenRange.location + tokenRange.length);
  }
  
  CFRelease(tokenizer);
  
  return chars;
  
}

/**
 * Split a text into a list of strings.  Reduce the texts to a CFStringRef of
 * hashes where where each Unicode character represents the substring for a CFRange.
 * @param text CFString to encode.
 * @param substringArray CFMutableArray of unique strings.
 * @param substringHash Map of strings to indices.
 * @param ranges C array of CFRange structs determining the subranges to hash.
 * @param ranges_count Count of the CFRange structs contained in ranges.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_rangesToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef substringArray, CFMutableDictionaryRef substringHash, CFRange *ranges, size_t ranges_count) {
  
  CFMutableStringRef chars = CFStringCreateMutable(kCFAllocatorDefault, 0);
  
	for (size_t i = 0; i < ranges_count; i++) {
    CFRange substringRange = ranges[i];
    
    diff_mungeTokenForRange(text, substringRange, chars, substringHash, substringArray);
  }
  
  return chars;
  
}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where where each Unicode character represents one word (or boundary between words).
 * @param text CFString to encode.
 * @param lineArray CFMutableArray of unique strings.
 * @param lineHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_wordsToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash) {

  return diff_tokensToCharsMungeCFStringCreate(text, tokenArray, tokenHash, kCFStringTokenizerUnitWordBoundary);
  
}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where where each Unicode character represents one sentence.
 * @param text CFString to encode.
 * @param lineArray CFMutableArray of unique strings.
 * @param lineHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_sentencesToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash) {

  return diff_tokensToCharsMungeCFStringCreate(text, tokenArray, tokenHash, kCFStringTokenizerUnitSentence);

}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where where each Unicode character represents one paragraph.
 * @param text CFString to encode.
 * @param lineArray CFMutableArray of unique strings.
 * @param lineHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_paragraphsToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash) {
  
  return diff_tokensToCharsMungeCFStringCreate(text, tokenArray, tokenHash, kCFStringTokenizerUnitParagraph);
  
}

/**
 * Split a text into a list of strings.   Reduce the texts to a CFStringRef of
 * hashes where each Unicode character represents one text fragment delimitered by line breaks (including the trailing line break characters if any).
 * In this context “line break” does not refere to “something you get when you press the return-key”. 
 * Instead it the refers to “line break boundaries” as defined in “UAX #14: Unicode Line Breaking Algorithm” (http://www.unicode.org/reports/tr14/). 
 * @param text CFString to encode.
 * @param lineArray CFMutableArray of unique strings.
 * @param lineHash Map of strings to indices.
 * @return Encoded CFStringRef.
 */
CFStringRef diff_lineBreakDelimiteredToCharsMungeCFStringCreate(CFStringRef text, CFMutableArrayRef tokenArray, CFMutableDictionaryRef tokenHash) {
  
  return diff_tokensToCharsMungeCFStringCreate(text, tokenArray, tokenHash, kCFStringTokenizerUnitLineBreak);
  
}

CFStringRef diff_charsToTokenCFStringCreate(CFStringRef charsString, CFArrayRef tokenArray) {
#define hashAtIndex(A)  hash_chars[(A)]
  CFMutableStringRef text = CFStringCreateMutable(kCFAllocatorDefault, 0);
  
  CFIndex hash_count = CFStringGetLength(charsString);

  const UniChar *hash_chars;
  UniChar *hash_buffer = NULL;
  diff_CFStringPrepareUniCharBuffer(charsString, &hash_chars, &hash_buffer, CFRangeMake(0, hash_count));
  
  for (CFIndex i = 0; i < hash_count; i++) {
    CFIndex tokenHash = (CFIndex)hashAtIndex(i);
    CFStringRef token = CFArrayGetValueAtIndex(tokenArray, tokenHash);
    CFStringAppend(text, token);
  }
  
  if (hash_buffer != NULL)  free(hash_buffer);
  
  return text;
#undef hashAtIndex
}

/**
 * Given two strings, compute a score representing whether the internal
 * boundary falls on logical boundaries.
 * Scores range from 6 (best) to 0 (worst).
 * @param one First CFStringRef.
 * @param two Second CFStringRef.
 * @return The score.
 */
CFIndex diff_cleanupSemanticScore(CFStringRef one, CFStringRef two) {
  static Boolean firstRun = true;
  static CFCharacterSetRef alphaNumericSet = NULL;
  static CFCharacterSetRef whiteSpaceSet = NULL;
  static CFCharacterSetRef controlSet = NULL;
  static regex_t blankLineEndRegEx;
  static regex_t blankLineStartRegEx;

  if (firstRun) {
    alphaNumericSet = CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric);
    whiteSpaceSet = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
    controlSet = CFCharacterSetGetPredefined(kCFCharacterSetControl);

    // Define some regex patterns for matching boundaries.
    int status;
    status = regcomp(&blankLineEndRegEx, "\n\r?\n$", REG_EXTENDED | REG_NOSUB);
    check(status == 0);
    status = regcomp(&blankLineStartRegEx, "^\r?\n\r?\n", REG_EXTENDED | REG_NOSUB);
    check(status == 0);

    firstRun = false;
  }

  if (CFStringGetLength(one) == 0 || CFStringGetLength(two) == 0) {
    // Edges are the best.
    return 6;
  }

  // Each port of this function behaves slightly differently due to
  // subtle differences in each language's definition of things like
  // 'whitespace'.  Since this function's purpose is largely cosmetic,
  // the choice has been made to use each language's native features
  // rather than force total conformity.
  UniChar char1 =
  CFStringGetCharacterAtIndex(one, (CFStringGetLength(one) - 1));
  UniChar char2 =
  CFStringGetCharacterAtIndex(two, 0);
  Boolean nonAlphaNumeric1 =
  !CFCharacterSetIsCharacterMember(alphaNumericSet, char1);
  Boolean nonAlphaNumeric2 =
  !CFCharacterSetIsCharacterMember(alphaNumericSet, char2);
  Boolean whitespace1 =
  nonAlphaNumeric1 && CFCharacterSetIsCharacterMember(whiteSpaceSet, char1);
  Boolean whitespace2 =
  nonAlphaNumeric2 && CFCharacterSetIsCharacterMember(whiteSpaceSet, char2);
  Boolean lineBreak1 =
  whitespace1 && CFCharacterSetIsCharacterMember(controlSet, char1);
  Boolean lineBreak2 =
  whitespace2 && CFCharacterSetIsCharacterMember(controlSet, char2);
  Boolean blankLine1 =
  lineBreak1 && diff_regExMatch(one, &blankLineEndRegEx);
  Boolean blankLine2 =
  lineBreak2 && diff_regExMatch(two, &blankLineStartRegEx);
  
  if (blankLine1 || blankLine2) {
    // Five points for blank lines.
    return 5;
  } else if (lineBreak1 || lineBreak2) {
    // Four points for line breaks.
    return 4;
  } else if (nonAlphaNumeric1 && !whitespace1 && whitespace2) {
    // Three points for end of sentences.
    return 3;
  } else if (whitespace1 || whitespace2) {
    // Two points for whitespace.
    return 2;
  } else if (nonAlphaNumeric1 || nonAlphaNumeric2) {
    // One point for non-alphanumeric.
    return 1;
  }
  return 0;
}

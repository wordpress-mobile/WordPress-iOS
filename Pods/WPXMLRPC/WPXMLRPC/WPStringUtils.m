// WPStringUtils.m
//
// Copyright (c) 2013 WordPress - http://wordpress.org/
// Based on Eric Czarny's xmlrpc library - https://github.com/eczarny/xmlrpc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WPStringUtils.h"

@implementation WPStringUtils

+ (NSString *)unescapedStringWithString:(NSString *)aString {
    NSMutableString *string = [NSMutableString stringWithString:aString];

    [string replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&#x27;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&#x39;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&#x92;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&#x96;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"&amp;"  withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [string length])];

    return [NSString stringWithString:string];
}

+ (NSString *)escapedStringWithString:(NSString *)aString {
    NSMutableString *string = [NSMutableString stringWithString:aString];

    // NOTE:we use unicode entities instead of &amp; &gt; &lt; etc. since some hosts (powweb, fatcow, and similar)
    // have a weird PHP/libxml2 combination that ignores regular entities
    [string replaceOccurrencesOfString:@"&"  withString:@"&#38;" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@">"  withString:@"&#62;" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"<"  withString:@"&#60;" options:NSLiteralSearch range:NSMakeRange(0, [string length])];

    return [NSString stringWithString:string];
}

@end
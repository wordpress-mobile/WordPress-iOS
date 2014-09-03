//
//  SISLLogParser.h
//  subliminal-instrument
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

@protocol SISLLogParserDelegate;

/**
 Instances of `SISLLogParser` (parsers) parse Subliminal test logs into
 series of discrete events.
 
 The logs are intended to be parsed in real-time, by a client feeding each line
 output by an `instruments` executable (running Subliminal tests) to a parser's
 `-parseStdoutLine:` and `-parseStderrLine:` methods. When an event is parsed,
 the log parser will call the client, its delegate, with the event. 
 */
@interface SISLLogParser : NSObject

/**
 The log parser's delegate, which is notified when events are parsed from the logs.
 */
@property (nonatomic, weak) id<SISLLogParserDelegate> delegate;

/**
 Parses a message written by an `instruments` executable to `stdout`.
 
 The parser will notify its delegate if an event is parsed from the log message.

 @param message A line of output written by an `instruments` executable to `stdout`.
 */
- (void)parseStdoutLine:(NSString *)message;

/**
 Parses a message written by an `instruments` executable to `stderr`.

 The parser will notify its delegate if an event is parsed from the log message.

 @param message A line of output written by an `instruments` executable to `stderr`.
 */
- (void)parseStderrLine:(NSString *)message;

@end


/**
 The `SISLLogParserDelegate` protocol defines the methods implemented by delegates
 of `SISLLogParser` objects.
 */
@protocol SISLLogParserDelegate <NSObject>

@required

/**
 Sent by the parser object to the delegate when an event is parsed from
 the `instruments` executable's output.
 
 @param parser The parser object.
 @param event The event that was parsed. See `SISLLogEvents.h`
              for the format of this dictionary.
 */
- (void)parser:(SISLLogParser *)parser didParseEvent:(NSDictionary *)event;

@end

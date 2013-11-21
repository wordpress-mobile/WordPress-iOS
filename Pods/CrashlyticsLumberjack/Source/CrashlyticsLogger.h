//
//  CrashlyticsLogger.h
//
//  Created by Simons, Mike on 5/16/13.
//  Copyright (c) 2013 TechSmith. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>

@interface CrashlyticsLogger : DDAbstractLogger

+(CrashlyticsLogger*) sharedInstance;

@end

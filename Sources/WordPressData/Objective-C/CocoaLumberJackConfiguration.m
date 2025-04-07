@import CocoaLumberjack;

DDLogLevel ddLogLevel = DDLogLevelInfo;

void SetCocoaLumberjackObjCLogLevel(NSUInteger ddLogLevelRawValue)
{
    ddLogLevel = (DDLogLevel)ddLogLevelRawValue;
}

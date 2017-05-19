#import "WPSharedLogging.h"
#import "WPSharedLoggingPrivate.h"

int WPSharedGetLoggingLevel() {
    return ddLogLevel;
}

void WPSharedSetLoggingLevel(int level) {
    ddLogLevel = level;
}

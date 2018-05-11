#import "WPAuthenticatorLogging.h"
#import "WPAuthenticatorLoggingPrivate.h"

int WPSharedGetLoggingLevel() {
    return ddLogLevel;
}

void WPSharedSetLoggingLevel(int level) {
    ddLogLevel = level;
}

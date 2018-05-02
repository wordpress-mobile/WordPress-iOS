#import "WPAuthenticatorLogging.h"
#import "WPAuthenticatorLoggingPrivate.h"

int WPAuthenticatorGetLoggingLevel() {
    return ddLogLevel;
}

void WPAuthenticatorSetLoggingLevel(int level) {
    ddLogLevel = level;
}

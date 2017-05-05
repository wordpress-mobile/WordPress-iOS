#import "WPStatsLogging.h"
#import "Logging.h"

int WPStatsGetLoggingLevel() {
  return ddLogLevel;
}

void WPStatsSetLoggingLevel(int level) {
  ddLogLevel = level;
}

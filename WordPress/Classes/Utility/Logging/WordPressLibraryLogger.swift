import CocoaLumberjack
import AutomatticTracks
import WordPressShared

class WordPressLibraryLogger: NSObject, TracksLoggingDelegate, WordPressLoggingDelegate {

    func logError(_ str: String) {
        DDLogError(str)
    }

    func logWarning(_ str: String) {
        DDLogWarn(str)
    }

    func logInfo(_ str: String) {
        DDLogInfo(str)
    }

    func logDebug(_ str: String) {
        DDLogDebug(str)
    }

    func logVerbose(_ str: String) {
        DDLogVerbose(str)
    }
}

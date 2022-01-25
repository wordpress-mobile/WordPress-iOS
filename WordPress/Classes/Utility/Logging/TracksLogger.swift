import CocoaLumberjack
import AutomatticTracks

class TracksLogger: NSObject, TracksLoggingDelegate {

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

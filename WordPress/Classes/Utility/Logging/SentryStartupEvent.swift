import Foundation
import AutomatticTracks
import Sentry

private struct ErrorWithCaller {
    let error: NSError
    let caller: String
}

/**
WARNING: This class was created to track events of failures during
startup time. This will block the thread. Do not use unless you're sure.
*/
@objc class SentryStartupEvent: NSObject {
    private typealias UserInfo = [String: Any]

    private var errors = [ErrorWithCaller]()

    func add(error: NSError, file: String = #file, function: String = #function, line: UInt = #line) {
        let filename = (file as NSString).lastPathComponent

        errors.append(ErrorWithCaller(error: error, caller: "\(function) (\(filename):\(line))"))
    }

    func add(error: Error, file: String = #file, function: String = #function, line: UInt = #line) {
        add(error: error as NSError, file: file, function: function, line: line)
    }

    @objc(addError:file:function:line:)
    func _objc_add(error: NSError, file: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        add(error: error, file: String(cString: file), function: String(cString: function), line: line)
    }

    // Send the event and block the thread until it was actually sent
    @objc func send(title: String) {
        let userInfo = errors.enumerated().reduce(into: [String: Any](), { (result, arg1) in
            let (index, errorWithCaller) = arg1
            let error = errorWithCaller.error
            result["Error \(index + 1)"] = [
                "Method": errorWithCaller.caller,
                "Domain": error.domain,
                "Code": error.code,
                "Description": error.localizedDescription,
                "User Info": error.userInfo.description
            ]
        })

        let error = NSError(domain: title, code: -1, userInfo: [NSLocalizedDescriptionKey: title])
        do {
            try WordPressAppDelegate.crashLogging?.logErrorAndWait(error, userInfo: userInfo, level: SentryLevel.fatal)
        } catch let err {
            DDLogError("⛔️ Unable to send startup error message to Sentry:")
            DDLogError(err.localizedDescription)
        }
    }
}

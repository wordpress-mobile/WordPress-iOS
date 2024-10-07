import Foundation
import CocoaLumberjackSwift

@inlinable
public func DDLogVerbose(_ message: @autoclosure () -> DDLogMessageFormat, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    CocoaLumberjackSwift.DDLogVerbose(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogDebug(_ message: @autoclosure () -> DDLogMessageFormat, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    CocoaLumberjackSwift.DDLogDebug(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogInfo(_ message: @autoclosure () -> DDLogMessageFormat, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    CocoaLumberjackSwift.DDLogInfo(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogWarn(_ message: @autoclosure () -> DDLogMessageFormat, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    CocoaLumberjackSwift.DDLogWarn(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogError(_ message: @autoclosure () -> DDLogMessageFormat, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    CocoaLumberjackSwift.DDLogError(message(), file: file, function: function, line: line)
}

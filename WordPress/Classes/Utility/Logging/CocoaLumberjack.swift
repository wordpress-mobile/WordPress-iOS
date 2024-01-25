import Foundation
import CocoaLumberjack

@inlinable
public func DDLogVerbose(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
//    CocoaLumberjack.DDLogVerbose(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogDebug(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
//    CocoaLumberjack.DDLogDebug(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogInfo(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
//    CocoaLumberjack.DDLogInfo(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogWarn(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
//    CocoaLumberjack.DDLogWarn(message(), file: file, function: function, line: line)
}

@inlinable
public func DDLogError(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
//    CocoaLumberjack.DDLogError(message(), file: file, function: function, line: line)
}

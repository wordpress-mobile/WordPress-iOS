import WordPressSharedObjC

public func WPLogError(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPLogvError(format, $0) }
}

public func WPLogWarning(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPLogvWarning(format, $0) }
}

public func WPLogInfo(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPLogvInfo(format, $0) }
}

public func WPLogDebug(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPLogvDebug(format, $0) }
}

public func WPLogVerbose(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPLogvVerbose(format, $0) }
}

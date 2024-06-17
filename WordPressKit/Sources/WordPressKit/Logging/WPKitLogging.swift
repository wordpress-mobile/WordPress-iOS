func WPKitLogError(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPKitLogvError(format, $0) }
}

func WPKitLogWarning(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPKitLogvWarning(format, $0) }
}

func WPKitLogInfo(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPKitLogvInfo(format, $0) }
}

func WPKitLogDebug(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPKitLogvDebug(format, $0) }
}

func WPKitLogVerbose(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPKitLogvVerbose(format, $0) }
}

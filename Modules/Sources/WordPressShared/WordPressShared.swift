#if SWIFT_PACKAGE

@_exported import WordPressSharedObjC

#endif

func WPSharedLogError(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPSharedLogvError(format, $0) }
}

func WPSharedLogWarning(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPSharedLogvWarning(format, $0) }
}

func WPSharedLogInfo(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPSharedLogvInfo(format, $0) }
}

func WPSharedLogDebug(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPSharedLogvDebug(format, $0) }
}

func WPSharedLogVerbose(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPSharedLogvVerbose(format, $0) }
}

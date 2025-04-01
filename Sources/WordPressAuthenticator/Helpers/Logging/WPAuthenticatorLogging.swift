func WPAuthenticatorLogError(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPAuthenticatorLogvError(format, $0) }
}

func WPAuthenticatorLogWarning(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPAuthenticatorLogvWarning(format, $0) }
}

func WPAuthenticatorLogInfo(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPAuthenticatorLogvInfo(format, $0) }
}

func WPAuthenticatorLogDebug(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPAuthenticatorLogvDebug(format, $0) }
}

func WPAuthenticatorLogVerbose(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { WPAuthenticatorLogvVerbose(format, $0) }
}

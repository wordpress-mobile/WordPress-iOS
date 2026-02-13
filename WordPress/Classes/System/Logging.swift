import Logging

struct Loggers {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static let subsystem = Bundle.main.bundleIdentifier!

    static let app = Logger(label: subsystem)

    /// Logs the HTTP network messages.
    static let networking = Logger(label: subsystem + ".network")
}

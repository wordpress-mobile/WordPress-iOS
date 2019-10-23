import Foundation

// This should probably be added to WordPressShared

private let longStringWithTimeFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .long
    df.timeStyle = .short
    return df
}()

private let longStringFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .long
    return df
}()

extension Date {
    public func longStringWithTime() -> String {
        return longStringWithTimeFormatter.string(from: self)
    }

    public func longString() -> String {
        return longStringFormatter.string(from: self)
    }
}

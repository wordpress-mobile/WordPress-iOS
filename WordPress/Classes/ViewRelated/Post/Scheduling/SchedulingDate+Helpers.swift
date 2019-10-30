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

    public static var farFutureDate: Date {
        return Date(timeIntervalSinceReferenceDate: (24*60*60)*365*50) // 50 Years out
    }

    public static var farPastDate: Date {
        return Date(timeIntervalSinceReferenceDate: (-24*60*60)*365*50) // 50 Years back
    }

    public func longStringWithTime() -> String {
        return longStringWithTimeFormatter.string(from: self)
    }

    public func longString() -> String {
        return longStringFormatter.string(from: self)
    }
}

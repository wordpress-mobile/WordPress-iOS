import Foundation

// This should probably be added to WordPressShared

extension Date {

    public static var farFutureDate: Date {
        return Date(timeIntervalSinceReferenceDate: (24*60*60)*365*50) // 50 Years out
    }

    public static var farPastDate: Date {
        return Date(timeIntervalSinceReferenceDate: (-24*60*60)*365*50) // 50 Years back
    }
}

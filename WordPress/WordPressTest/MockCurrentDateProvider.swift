import Foundation
@testable import WordPress

class MockCurrentDateProvider: CurrentDateProvider {
    var dateToReturn: Date?

    func date() -> Date {
        return dateToReturn ?? Date()
    }
}

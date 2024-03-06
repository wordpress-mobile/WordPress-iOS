import Foundation

public struct UIElementNotFoundError: Error {
    public let message: String

    init(message: String) {
        self.message = message
    }
}

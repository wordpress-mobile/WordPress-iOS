import Foundation

public struct QRLoginValidationResponse: Decodable {
    /// The name of the browser that the user has requested the login from
    /// IE: Chrome, Firefox
    /// This may be null if the browser could not be determined
    public var browser: String?

    /// The City, State the user has requested the login from
    /// IE: Columbus, Ohio
    public var location: String
}

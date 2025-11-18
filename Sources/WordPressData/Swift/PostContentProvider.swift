import Foundation

@objc public protocol PostContentProvider: NSObjectProtocol {
    func titleForDisplay() -> String?
    func authorForDisplay() -> String?
    func contentForDisplay() -> String?
    func contentPreviewForDisplay() -> String?
    func avatarURLForDisplay() -> URL?
    func gravatarEmailForDisplay() -> String?
    func dateForDisplay() -> Date?

    @objc optional func blogNameForDisplay() -> String?
    @objc optional func featuredImageURLForDisplay() -> URL?
    @objc optional func authorURL() -> URL?
    @objc optional func tagsForDisplay() -> [String]?
}

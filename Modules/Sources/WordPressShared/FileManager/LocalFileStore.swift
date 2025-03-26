import Foundation

public protocol LocalFileStore {
    func data(from url: URL) throws -> Data

    func fileExists(at url: URL) -> Bool

    @discardableResult
    func save(contents: Data, at url: URL) -> Bool

    func containerURL(forAppGroup appGroup: String) -> URL?

    func removeItem(at url: URL) throws

    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

public extension LocalFileStore {
    func data(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}

import Foundation

extension FileManager: LocalFileStore {
    public func containerURL(forAppGroup appGroup: String) -> URL? {
        return containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    public func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }

    @discardableResult
    public func save(contents: Data, at url: URL) -> Bool {
        return createFile(atPath: url.path, contents: contents)
    }
}

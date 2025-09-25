import Foundation

public actor DiskCache {

    struct Wrapper<T>: Codable where T: Codable {
        let date: Date
        let data: T
    }

    public func store<T>(object: T, for key: String) throws where T: Codable {
        try self.ensureCacheDirectoryExists()

        let wrapper = Wrapper(date: Date(), data: object)
        let data = try JSONEncoder().encode(wrapper)

        FileManager.default.createFile(atPath: self.cacheURL(for: key).path(), contents: data)
    }

    public func retrieve<T>(for key: String, notOlderThan date: Date? = nil) throws -> T? where T: Codable {
        try self.ensureCacheDirectoryExists()

        let path = self.cacheURL(for: key)
        guard FileManager.default.fileExists(at: path) else {
            return nil
        }

        let data = try Data(contentsOf: path)
        let wrapper = try JSONDecoder().decode(Wrapper<T>.self, from: data)

        if let date {
            if wrapper.date > date {
                return nil
            }
        }

        return wrapper.data
    }

    private func ensureCacheDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: cacheURL(for: "").deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func cacheURL(for key: String) -> URL {
        URL.cachesDirectory
            .appendingPathComponent("object-cache")
            .appendingPathComponent(key)
            .appendingPathExtension("json")
    }
}

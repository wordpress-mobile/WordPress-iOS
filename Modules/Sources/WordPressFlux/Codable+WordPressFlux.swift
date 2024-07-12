import Foundation

/// Those extensions are used by `QueryStore` to help with persisting data to disk.
internal extension Encodable {
    func saveJSON(at url: URL, using encoder: JSONEncoder = JSONEncoder()) throws {
        let encodedStore = try encoder.encode(self)
        try encodedStore.write(to: url, options: [.atomic])
    }
}

internal extension Decodable {
    static func loadJSON(from url: URL, using decoder: JSONDecoder = JSONDecoder()) throws -> Self? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let state = try decoder.decode(Self.self, from: data)
        return state
    }
}

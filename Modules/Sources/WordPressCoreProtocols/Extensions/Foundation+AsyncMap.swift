import Foundation

public extension Collection {
    func asyncMap<T>(operation: (Element) async throws -> T) async throws -> [T] {
        var newCollection = [T]()

        for element in self {
            let newElement = try await operation(element)
            newCollection.append(newElement)
        }

        return newCollection
    }
}

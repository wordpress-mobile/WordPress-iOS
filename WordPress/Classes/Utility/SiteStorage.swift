import SwiftUI
import WordPressData

@propertyWrapper
struct SiteStorage<Value: Codable>: DynamicProperty {
    @AppStorage private var data: Data
    private let defaultValue: Value

    var wrappedValue: Value {
        get {
            (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
        nonmutating set {
            data = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }

    init(wrappedValue: Value, _ key: String, blog: TaggedManagedObjectID<Blog>,
         store: UserDefaults? = nil) {
        self.defaultValue = wrappedValue
        let scopedKey = SiteStorageReader.scopedKey(key, blog: blog)
        _data = AppStorage(wrappedValue: Data(), scopedKey, store: store)
    }
}

enum SiteStorageReader {
    static func read<T: Decodable>(_ type: T.Type, key: String, blog: Blog) -> T? {
        let scopedKey = scopedKey(key, blog: TaggedManagedObjectID(blog))
        guard let data = UserDefaults.standard.data(forKey: scopedKey) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    fileprivate static var prefix: String { "site-storage" }
    fileprivate static var separator: String { "|" }

    fileprivate static func scopedKey(
        _ key: String,
        blog: TaggedManagedObjectID<Blog>
    ) -> String {
        [prefix, blog.objectID.uriRepresentation().absoluteString, key]
            .joined(separator: separator)
    }
}

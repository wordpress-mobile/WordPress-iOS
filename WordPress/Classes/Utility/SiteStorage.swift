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
        let scopedKey = SiteStorageAccess.scopedKey(key, blog: blog)
        _data = AppStorage(wrappedValue: Data(), scopedKey, store: store)
    }

    fileprivate init(wrappedValue: Value, _ key: String, scope: String,
         store: UserDefaults? = nil) {
        self.defaultValue = wrappedValue
        let scopedKey = SiteStorageAccess.scopedKey(key, scope: scope)
        _data = AppStorage(wrappedValue: Data(), scopedKey, store: store)
    }
}

enum SiteStorageAccess {
    static func read<T: Decodable>(_ type: T.Type, key: String, blog: TaggedManagedObjectID<Blog>) -> T? {
        let scopedKey = scopedKey(key, blog: blog)
        guard let data = UserDefaults.standard.data(forKey: scopedKey) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T, key: String, blog: TaggedManagedObjectID<Blog>) {
        let scopedKey = scopedKey(key, blog: blog)
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        UserDefaults.standard.set(data, forKey: scopedKey)
    }

    static func exists(key: String, blog: TaggedManagedObjectID<Blog>) -> Bool {
        let scopedKey = scopedKey(key, blog: blog)
        return UserDefaults.standard.object(forKey: scopedKey) != nil
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

    fileprivate static func scopedKey(
        _ key: String,
        scope: String
    ) -> String {
        [prefix, scope, key]
            .joined(separator: separator)
    }
}

#if DEBUG

private struct SiteStoragePreviewContent: View {
    @SiteStorage("counter", scope: "tests") private var counter = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \(counter)")
                .font(.headline)
            Button("Increment") {
                let key = SiteStorageAccess.scopedKey("counter", scope: "tests")

                let newValue = counter + 1
                let encoded = (try? JSONEncoder().encode(newValue)) ?? Data()
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
}

#Preview {
    SiteStoragePreviewContent()
}

#endif

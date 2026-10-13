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

extension SiteStorageAccess {
    /// Removes the custom post types that earlier versions pinned to the site menu. The site menu
    /// has listed every custom post type since 27.4.
    ///
    /// TODO: Delete in 27.6, when few users still update from a version that wrote these keys.
    static func removePinnedPostTypes(from defaults: UserDefaults = .standard) {
        let keyPrefix = prefix + separator
        let keySuffix = separator + "pinned-post-types"
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix(keyPrefix) && key.hasSuffix(keySuffix) {
            defaults.removeObject(forKey: key)
        }
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

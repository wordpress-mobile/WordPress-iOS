import CoreData
import CryptoKit

public extension NSManagedObject {
    func setRawValue<ValueType: RawRepresentable>(_ value: ValueType?, forKey key: String) {
        willChangeValue(forKey: key)
        setPrimitiveValue(value?.rawValue, forKey: key)
        didChangeValue(forKey: key)
    }

    func rawValue<ValueType: RawRepresentable>(forKey key: String) -> ValueType? {
        willAccessValue(forKey: key)
        let result = primitiveValue(forKey: key) as? ValueType.RawValue
        didAccessValue(forKey: key)
        return result.flatMap({ ValueType(rawValue: $0) })
    }

    var locallyUniqueId: String {
        let data = Data(self.objectID.uriRepresentation().absoluteString.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}

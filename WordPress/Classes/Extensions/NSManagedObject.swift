import CoreData

extension NSManagedObject {
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
}

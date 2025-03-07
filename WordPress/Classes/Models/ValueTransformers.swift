import Foundation

extension ValueTransformer {
    @objc
    static func registerCustomTransformers() {
        NSErrorValueTransformer.register()
        SetValueTransformer.register()
    }
}

@objc
final class NSErrorValueTransformer: NSSecureUnarchiveFromDataTransformer {

    static let name = NSValueTransformerName(rawValue: String(describing: NSErrorValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSError.self]
    }

    @objc
    public static func register() {
        let transformer = NSErrorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

@objc
final class SetValueTransformer: NSSecureUnarchiveFromDataTransformer {

    static let name = NSValueTransformerName(rawValue: String(describing: SetValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSSet.self]
    }

    @objc
    public static func register() {
        let transformer = SetValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

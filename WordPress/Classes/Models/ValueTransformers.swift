import Foundation

extension ValueTransformer {
    @objc
    static func registerCustomTransformers() {
        guard #available(iOS 12.0, *) else {
            return
        }

        CoordinateValueTransformer.register()
        NSErrorValueTransformer.register()
        SetValueTransformer.register()
    }
}

@available(iOS 12.0, *)
@objc
final class CoordinateValueTransformer: NSSecureUnarchiveFromDataTransformer {

    static let name = NSValueTransformerName(rawValue: String(describing: CoordinateValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        return [Coordinate.self]
    }

    @objc
    public static func register() {
        let transformer = CoordinateValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

@available(iOS 12.0, *)
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

@available(iOS 12.0, *)
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

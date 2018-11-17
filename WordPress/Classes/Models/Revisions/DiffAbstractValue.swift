import Foundation
import CoreData


class DiffAbstractValue: NSManagedObject {
    enum Operation: String {
        case add
        case copy
        case del
        case unknown
    }

    enum DiffType: String {
        case title
        case content
        case unknown
    }

    @NSManaged private var diffOperation: String
    @NSManaged private var diffType: String

    @NSManaged var index: Int
    @NSManaged var value: String?

    var operation: Operation {
        get {
            return Operation(rawValue: diffOperation) ?? .unknown
        }
        set {
            diffOperation = newValue.rawValue
        }
    }

    var type: DiffType {
        get {
            return DiffType(rawValue: diffType) ?? .unknown
        }
        set {
            diffType = newValue.rawValue
        }
    }
}


extension DiffAbstractValue {
    var attributes: [NSAttributedString.Key: Any]? {
        switch operation {
        case .add: return [.backgroundColor: WPStyleGuide.extraLightBlue(),
                           .underlineStyle: NSNumber(value: 2),
                           .underlineColor: WPStyleGuide.wordPressBlue()]
        case .del: return [.backgroundColor: WPStyleGuide.extraLightRed(),
                           .underlineStyle: NSNumber(value: 2),
                           .underlineColor: WPStyleGuide.errorRed(),
                           .strikethroughStyle: NSNumber(value: 1),
                           .strikethroughColor: UIColor.black]
        default: return nil
        }
    }
}


private extension WPStyleGuide {
    static func extraLightBlue() -> UIColor {
        return UIColor(hexString: "e7f8ff")
    }

    static func extraLightRed() -> UIColor {
        return UIColor(hexString: "fbeeee")
    }
}

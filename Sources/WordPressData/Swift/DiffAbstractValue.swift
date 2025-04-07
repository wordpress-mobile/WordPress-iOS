import Foundation
import CoreData

public class DiffAbstractValue: NSManagedObject {
    public enum Operation: String {
        case add
        case copy
        case del
        case unknown
    }

    public enum DiffType: String {
        case title
        case content
        case unknown
    }

    @NSManaged private var diffOperation: String
    @NSManaged private var diffType: String

    @NSManaged public var index: Int
    @NSManaged public var value: String?

    public var operation: Operation {
        get {
            return Operation(rawValue: diffOperation) ?? .unknown
        }
        set {
            diffOperation = newValue.rawValue
        }
    }

    public var type: DiffType {
        get {
            return DiffType(rawValue: diffType) ?? .unknown
        }
        set {
            diffType = newValue.rawValue
        }
    }
}

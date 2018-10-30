import Foundation
import CoreData


class RevisionDiffAbstractValue: NSManagedObject {
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

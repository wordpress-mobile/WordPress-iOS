import Foundation
import MediaEditor

extension Array where Element == MediaEditorOperation {
    var description: String {
        return self.map { $0.description }.joined(separator: ", ")
    }
}

extension MediaEditorOperation {
    var description: String {
        switch self {
        case .crop:
            return "crop"
        case .rotate:
            return "rotate"
        case .filter:
            return "filter"
        case .draw:
            return "draw"
        case .other:
            return "other"
        }
    }
}

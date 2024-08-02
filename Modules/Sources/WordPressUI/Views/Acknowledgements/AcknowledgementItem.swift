import Foundation

public struct AcknowledgementItem: Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let license: String

    public init(id: String, title: String, description: String?, license: String) {
        self.id = id
        self.title = title
        self.description = description
        self.license = license
    }
}

extension AcknowledgementItem: Comparable {
    public static func < (lhs: AcknowledgementItem, rhs: AcknowledgementItem) -> Bool {
        lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

package extension AcknowledgementItem {
    static let sampleData: [AcknowledgementItem] = [
        AcknowledgementItem(id: "1", title: "Test Title 1", description: "It's good, actually", license: UUID().uuidString),
        AcknowledgementItem(id: "2", title: "Test Title 2", description: nil, license: UUID().uuidString),
    ]
}

import SwiftUI
import DesignSystem

public struct SectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.caption2).fontWeight(.medium)
            .foregroundStyle(Color.secondary)
    }
}

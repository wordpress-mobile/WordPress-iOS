import SwiftUI
import DesignSystem

public struct SettingsCheckmark: View {
    let isSelected: Bool

    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    public var body: some View {
        Image(systemName: "checkmark")
            .font(.headline)
            .opacity(isSelected ? 1 : 0)
            .foregroundStyle(AppColor.primary)
            .symbolEffect(.bounce.up, value: isSelected)
    }
}

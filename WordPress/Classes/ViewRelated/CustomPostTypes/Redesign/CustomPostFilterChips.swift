import DesignSystem
import SwiftUI

/// Horizontally scrolling filter chips standing in for the list's tab bar.
///
/// Scrolling is the point: unlike a fixed tab bar this can take on extra
/// filters later without squeezing the existing ones. The selected chip is
/// kept in view when the selection changes.
struct CustomPostFilterChips: View {
    let items: [CustomPostTab]
    @Binding var selection: CustomPostTab

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { tab in
                        chip(for: tab)
                            .id(tab)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: selection) {
                withAnimation {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
        }
    }

    private func chip(for tab: CustomPostTab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            Text(tab.localizedTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? AppColor.primary : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AppColor.primary.opacity(0.15) : Color(.secondarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

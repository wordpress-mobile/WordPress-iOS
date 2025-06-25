import SwiftUI
import DesignSystem

/// A standard WordPress form with cards.
public struct StandardForm<Content: View>: View {
    @ViewBuilder public  let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                content()
            }
            .padding()
        }
        .textFieldStyle(.roundedBorder)
        .background(AppColor.secondaryBackground)
    }
}

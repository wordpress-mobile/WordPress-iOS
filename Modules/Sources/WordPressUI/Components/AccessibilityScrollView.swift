import SwiftUI

/// Wraps its immediate subview in a ScrollView at accessibility text sizes
///
@available(iOS 16.4, *)
struct AccessibilityScrollView<Content: View>: View {

    @Environment(\.dynamicTypeSize)
    var dynamicTypeSize

    @State
    private var contentOverflow: Bool = false

    var innerView: () -> Content

    var body: some View {
        ScrollView(.vertical) {
            innerView()
        }.scrollBounceBehavior(.basedOnSize, axes: [.vertical])
    }
}

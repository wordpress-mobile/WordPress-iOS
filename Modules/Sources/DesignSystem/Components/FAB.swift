import SwiftUI

public struct FAB: View {
    let image: Image
    let action: (() -> Void)?

    public init(image: Image = Image(systemName: "plus"), action: (() -> Void)? = nil) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility1) // important to be attached from the outside
    }

    @ViewBuilder
    private var content: some View {
        if let action {
            Button(action: action) {
                FABContentView(image: image)
            }
        } else {
            FABContentView(image: image)
        }
    }
}

private struct FABContentView: View {
    let image: Image

    @ScaledMetric(relativeTo: .title2) private var size = 54.0
    @ScaledMetric(relativeTo: .title2) private var shadowRadios = 4.0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        image
            .font(.title2)
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(colorScheme == .light ? Color(.label) : Color(.systemGray2))
            .cornerRadius(size / 2)
            .shadow(radius: shadowRadios)
    }
}

@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 200, height: 200)) {
    FAB(action: {})
}

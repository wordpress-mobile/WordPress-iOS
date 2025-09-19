import SwiftUI

public struct FAB: View {
    let image: Image
    let action: (() -> Void)?

    public init(image: Image = Image(systemName: "plus"), action: (() -> Void)? = nil) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        if #available(iOS 26, *) {
            Button(action: action ?? {}) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(Color(.systemBackground))
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(Color(.label).opacity(0.8))
        } else {
            legacy
        }
    }

    @ViewBuilder
    private var legacy: some View {
        Group {
            if let action {
                Button(action: action) {
                    FABContentView(image: image)
                }
            } else {
                FABContentView(image: image)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // important to be attached from the outside
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

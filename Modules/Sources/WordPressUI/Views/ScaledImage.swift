import SwiftUI

/// A simple view for scaling the given icon to the target size.
public struct ScaledImage: View {
    private let imageName: String
    @ScaledMetric(relativeTo: .body) var height = 17

    /// - warning: The image should have `Preserve Vector Data` option enabled
    /// for the best results.
    public init(_ name: String, height: CGFloat, relativeTo textSyle: Font.TextStyle = .body) {
        self.imageName = name
        self._height = ScaledMetric(wrappedValue: height, relativeTo: textSyle)
    }

    public var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
    }
}

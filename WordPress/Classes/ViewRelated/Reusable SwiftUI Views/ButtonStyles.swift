import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44.0)
            .font(.headline)
            .background(Color.DS.Background.brand)
            .foregroundColor(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Length.Radius.minHeightButton))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

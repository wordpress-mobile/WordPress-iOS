import Foundation
import SwiftUI

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: Self { PrimaryButtonStyle() }
}

public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
            .font(.headline)
            .background(.tint)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

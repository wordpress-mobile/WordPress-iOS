import SwiftUI

// MARK: - SwiftUI.Text
public extension Text {
    @ViewBuilder
    func style(_ style: TextStyle) -> some View {
        let font = Font.DS.font(style)
        self.font(font)
            .textCase(style.case)
    }
}

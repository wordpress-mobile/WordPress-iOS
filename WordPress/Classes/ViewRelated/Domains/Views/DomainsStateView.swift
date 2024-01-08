import Foundation
import SwiftUI
import DesignSystem

struct DomainsStateView: View {
    private let viewModel: DomainsStateViewModel

    init(viewModel: DomainsStateViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Length.Padding.single) {
            Text(viewModel.title)
                .font(Font.DS.heading3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.DS.Foreground.secondary)
            Text(viewModel.description)
                .font(Font.DS.Body.medium)
                .foregroundStyle(Color.DS.Foreground.secondary)
                .multilineTextAlignment(.center)
            if let button = viewModel.button {
                Spacer()
                    .frame(height: Length.Padding.single)
                DSButton(title: button.title, style: .init(emphasis: .primary, size: .medium)) {
                    button.action()
                }
            }
        }
    }
}

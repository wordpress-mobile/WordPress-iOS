import SwiftUI
import Foundation

struct DomainSetupNoticeView: View {

    let noticeText: String

    var body: some View {

        HStack() {
            Image(uiImage: .gridicon(.infoOutline))
                .frame(height: Metrics.iconHeight)
                .foregroundColor(Color(UIColor.muriel(color: .gray)))
                .accessibility(hidden: true)

            Spacer().frame(width: Metrics.iconToNoticeSpacing)

            Text(noticeText)
                .font(.footnote)
                .dynamicTypeSize(.large)
                .foregroundColor(Color(UIColor.muriel(color: .textSubtle)))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metrics.noticeBoxPadding)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiaryFill))
        .cornerRadius(Metrics.noticeBoxCornerRadius)
    }
}

// MARK: - Constants
private extension DomainSetupNoticeView {

    private enum Metrics {
        static let noticeBoxCornerRadius = 8.0
        static let noticeBoxPadding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let iconHeight = 24.0
        static let iconToNoticeSpacing = 16.0
    }
}

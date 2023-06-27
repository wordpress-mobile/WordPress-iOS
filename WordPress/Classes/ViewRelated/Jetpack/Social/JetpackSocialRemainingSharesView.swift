import SwiftUI

struct JetpackSocialRemainingSharesView: View {

    let viewModel: JetpackSocialRemainingSharesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack(spacing: 8.0) {
                if viewModel.displayWarning {
                    Image("icon-warning")
                        .resizable()
                        .frame(width: 16.0, height: 16.0)
                }
                remainingText
            }
            Text(Constants.subscribeText)
                .font(.callout)
                .foregroundColor(Color(UIColor.primary))
                .onTapGesture {
                    viewModel.onSubscribeTap()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 12.0, leading: 16.0, bottom: 12.0, trailing: 16.0))
        .background(Color(UIColor.listForeground))
    }

    private var remainingText: some View {
        let sharesRemainingString = String(format: Constants.remainingTextFormat, viewModel.remaining, viewModel.limit)
        let sharesRemaining = Text(sharesRemainingString).font(.callout)
        if viewModel.displayWarning {
            return sharesRemaining
        }
        let remainingDays = Text(Constants.remainingEndText).font(.callout).foregroundColor(.secondary)
        return sharesRemaining + remainingDays
    }

    private struct Constants {
        static let remainingTextFormat = NSLocalizedString("social.remainingshares.text.format",
                                                           value: "%1$d/%2$d social shares remaining",
                                                           comment: "Beginning text of the remaining social shares a user has left."
                                                           + " %1$d is their current remaining shares. %2$d is their share limit."
                                                           + " This text is combined with ' in the next 30 days' if there is no warning displayed.")
        static let remainingEndText = NSLocalizedString("social.remainingshares.text.part",
                                                        value: " in the next 30 days",
                                                        comment: "The second half of the remaining social shares a user has."
                                                        + " This is only displayed when there is no social limit warning.")
        static let subscribeText = NSLocalizedString("social.remainingshares.subscribe",
                                                     value: "Subscribe now to share more",
                                                     comment: "Title for the button to subscribe to Jetpack Social on the remaining shares view")
    }

}

struct JetpackSocialRemainingSharesViewModel {
    let remaining: Int
    let limit: Int
    let displayWarning: Bool
    let onSubscribeTap: () -> Void

    init(remaining: Int = 27,
         limit: Int = 30,
         displayWarning: Bool = false,
         onSubscribeTap: @escaping () -> Void) {
        self.remaining = remaining
        self.limit = limit
        self.displayWarning = displayWarning
        self.onSubscribeTap = onSubscribeTap
    }
}

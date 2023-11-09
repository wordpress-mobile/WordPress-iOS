import SwiftUI

struct RegisterDomainTransferFooterView: View {

    // MARK: - Types

    struct Configuration {

        let title: String
        let buttonTitle: String
        let buttonAction: () -> Void

        init(
            title: String = Strings.title,
            buttonTitle: String = Strings.buttonTitle,
            buttonAction: @escaping () -> Void
        ) {
            self.title = title
            self.buttonTitle = buttonTitle
            self.buttonAction = buttonAction
        }
    }

    struct Strings {
        static let title = NSLocalizedString(
            "register.domain.transfer.title",
            value: "Looking to transfer a domain you already own?",
            comment: "The title for the transfer footer view in Register Domain screen"
        )
        static let buttonTitle = NSLocalizedString(
            "register.domain.transfer.button.title",
            value: "Transfer domain",
            comment: "The button title for the transfer footer view in Register Domain screen"
        )
    }

    // MARK: - Properties

    let configuration: Configuration

    // MARK: - Views

    var body: some View {
        VStack(alignment: .leading, spacing: Length.Padding.double) {
            Text(configuration.title)
                .font(.body)
            Button(action: configuration.buttonAction) {
                Text(configuration.buttonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(Length.Padding.double)
    }
}

// MARK: - Previews

struct RegisterDomainTransferFooterView_Reviews: PreviewProvider {
    static var previews: some View {
        RegisterDomainTransferFooterView(configuration: .init(buttonAction: {}))
    }
}

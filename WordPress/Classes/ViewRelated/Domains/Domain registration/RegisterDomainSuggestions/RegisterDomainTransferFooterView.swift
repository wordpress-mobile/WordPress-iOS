import SwiftUI
import UIKit

final class RegisterDomainTransferFooterView: UIView {

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

    // MARK: - Views

    private var hostingController: UIHostingController<Content>?

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(light: .systemBackground, dark: .secondarySystemBackground)
        self.addTopBorder(withColor: .divider)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func setup(with configuration: Configuration, parent: UIViewController) {
        self.setup(with: Content(configuration: configuration), parent: parent)
    }

    private func setup(with content: Content, parent: UIViewController) {
        if let hostingController {
            hostingController.rootView = content
            hostingController.view.invalidateIntrinsicContentSize()
        } else {
            let hostingController = UIHostingController<Content>(rootView: content)
            self.add(hostingController: hostingController, parent: parent)
            self.constraint(hostingController: hostingController)
            self.hostingController = hostingController
        }
    }

    private func add(hostingController: UIHostingController<Content>, parent: UIViewController) {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        hostingController.willMove(toParent: parent)
        self.addSubview(hostingController.view)
        parent.add(hostingController)
        hostingController.didMove(toParent: parent)
    }

    private func constraint(hostingController: UIHostingController<Content>) {
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor, constant: Length.Padding.double),
            hostingController.view.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor, constant: -Length.Padding.double),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor, constant: Length.Padding.double),
            hostingController.view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Length.Padding.double),
        ])
    }

    // MARK: - Trait Collection

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.hostingController?.view.invalidateIntrinsicContentSize()
    }

}

// MARK: - SwiftUI

fileprivate struct Content: View {

    let configuration: Configuration

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
        .fixedSize(horizontal: false, vertical: true)
    }

    typealias Configuration = RegisterDomainTransferFooterView.Configuration

}

struct RegisterDomainTransferFooterView_Reviews: PreviewProvider {
    static var previews: some View {
        Content(configuration: .init(buttonAction: {}))
            .padding(Length.Padding.double)
    }
}

import UIKit
import DesignSystem
import SwiftUI
import WordPressUI

class XMLRPCDisabledCell: UITableViewCell {
    private weak var presenterViewController: UIViewController?

    private lazy var cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.masksToBounds = true
        view.layer.cornerRadius = DesignConstants.radius(.large)

        let content = UIHostingView(view: CardContent())
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        view.pinSubviewToAllEdges(content)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showAlert)))
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView)
    }

    func configure(with viewController: BlogDetailsViewController) {
        presenterViewController = viewController
    }

    @objc private func showAlert() {
        guard let presenter = presenterViewController else {
            return
        }

        let alert = AlertView {
            AlertHeaderView(title: Strings.alertTitle, description: Strings.alertMessage)
        } content: {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
        } actions: {
            AlertDismissButton()
        }

        alert.present(in: presenter)
    }
}

private struct CardContent: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading) {
                Text(Strings.cardTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(Strings.cardSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "info.circle.fill")
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private enum Strings {
    static let cardTitle = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.card.title",
        value: "XML-RPC Disabled",
        comment: "Title for the XML-RPC disabled card on blog details"
    )
    static let cardSubtitle = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.card.subtitle",
        value: "Some features may be limited",
        comment: "Subtitle for the XML-RPC disabled card on blog details"
    )

    static let alertTitle = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.title",
        value: "XML-RPC Disabled",
        comment: "Alert title for XML-RPC disabled"
    )

    static let alertMessage = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.message",
        value: "XML-RPC is currently unavailable on your site. The app is transitioning to WordPress REST API, but some features still require XML-RPC. You may experience limited functionality until this transition is complete.",
        comment: "Alert message explaining that XML-RPC is disabled on the site and some features may be limited"
    )
}

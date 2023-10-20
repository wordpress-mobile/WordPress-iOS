import SwiftUI

class TemplatePageTableViewCell: UITableViewCell {

    private let hostViewController: UIHostingController<TemplatePageView>

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        hostViewController = UIHostingController(rootView: TemplatePageView())
        hostViewController.view.translatesAutoresizingMaskIntoConstraints = false
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(hostViewController.view)
        contentView.pinSubviewToAllEdges(hostViewController.view)
        applyStyles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyStyles() {
        backgroundColor = .neutral(.shade5)
        separatorInset = .zero
    }

}

private struct TemplatePageView: View {
    var body: some View {
        HStack {
            text
            icon
        }
        .padding(EdgeInsets(top: 4.0, leading: 16.0, bottom: 8.0, trailing: 16.0))
        .background(Color(UIColor.listForeground))
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(Constants.title)
                .font(Font(WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)))
                .foregroundColor(Color(UIColor.label))
            Text(Constants.subtitle)
                .font(.footnote)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var icon: some View {
        Image(uiImage: .gridicon(.infoOutline))
            .resizable()
            .frame(width: 24.0, height: 24.0)
            .foregroundColor(Color(UIColor.textSubtle))
            .onTapGesture {
                WPAnalytics.track(.pageListEditHomepageInfoTapped)
                guard let url = URL(string: Constants.supportUrl) else {
                    return
                }
                UIApplication.shared.open(url)
            }
    }
}

private struct Constants {
    static let supportUrl = "https://wordpress.com/support/templates/"
    static let title = NSLocalizedString("pages.template.title",
                                         value: "Homepage",
                                         comment: "Title of the theme template homepage cell")
    static let subtitle = NSLocalizedString("pages.template.subtitle",
                                            value: "Your homepage is using a Theme template and will open in the web editor.",
                                            comment: "Subtitle of the theme template homepage cell")
}

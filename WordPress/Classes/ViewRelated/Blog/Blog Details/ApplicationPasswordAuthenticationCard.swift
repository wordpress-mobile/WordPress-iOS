import Foundation
import WordPressUI
import SwiftUI

public class ApplicationPasswordAuthenticationCardCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let view = UIHostingView(view: ApplicationPasswordAuthenticationCard())
        self.contentView.addSubview(view)
        view.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ApplicationPasswordAuthenticationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.red)

                Text(Strings.newTitle)
                    .foregroundColor(.primary)
            }
            .font(.headline)

            Text(Strings.description)
                .font(.callout)
                .foregroundColor(.primary)

            Text(Strings.authorize)
                .font(.callout.bold())
                .foregroundStyle(Color.accentColor)
        }
        .padding()
    }
}

private enum Strings {
    static let newTitle = NSLocalizedString("application.password.new.title", value: "New: Application Passwords", comment: "Title for the new application passwords feature")
    static let description = NSLocalizedString("application.password.description", value: "You can now grant the app permission to use application passwords for quick and secure access to your site content.", comment: "Description for the application passwords feature")
    static let authorize = NSLocalizedString("application.password.authorize", value: "Authorize", comment: "Button label to authorize application passwords")
}

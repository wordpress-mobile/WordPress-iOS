import SwiftUI
import WordPressUI
import WordPressKit

@MainActor
struct SubscriberRowView: View {
    let viewModel: SubscriberRowViewModel

    var body: some View {
        HStack(alignment: .center) {
            avatar.frame(width: 24, height: 24)
            Text(viewModel.title)
            Spacer()
            Text(viewModel.details)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var avatar: some View {
        switch viewModel.avatar {
        case .remote(let url):
            AvatarView(style: .single(url), diameter: 24, placeholderImage: Image("gravatar").resizable())
        case .email:
            Image(systemName: "envelope")
                .foregroundStyle(.tertiary)
        }
    }
}

@MainActor
final class SubscriberRowViewModel: Identifiable {
    var identifier: Int { subscriberID }
    var subscriberID: Int { subscriber.subscriberID }

    let title: String
    let avatar: Avatar
    let details: String

    enum Avatar {
        case remote(URL?)
        case email
    }

    private let blog: SubscribersBlog
    private let subscriber: SubscribersServiceRemote.GetSubscribersResponse.Subscriber

    init(blog: SubscribersBlog, subscriber: SubscribersServiceRemote.GetSubscribersResponse.Subscriber) {
        self.blog = blog
        self.subscriber = subscriber

        if subscriber.dotComUserID == 0 {
            self.avatar = .email
        } else {
            self.avatar = .remote(subscriber.avatar.flatMap(URL.init))
        }
        self.title = subscriber.displayName ?? subscriber.emailAddress ?? ""
        self.details = dateFormatter.localizedString(for: subscriber.dateSubscribed, relativeTo: .now)
    }

    func makeDetailsViewModel() -> SubsriberDetailsViewModel {
        SubsriberDetailsViewModel(blog: blog, subscriber: subscriber)
    }
}

private let dateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .abbreviated
    return formatter
}()

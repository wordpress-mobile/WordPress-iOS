import SwiftUI
import WordPressUI
import WordPressKit

@MainActor
struct SubscriberRowView: View {
    let viewModel: SubscriberRowViewModel

    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .center) {
            avatar.frame(width: 24, height: 24)
            Text(viewModel.title)
            Spacer()
            if viewModel.isDeleting {
                ProgressView()
            } else {
                Text(viewModel.details)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .contextMenu {
            Button(Strings.delete, role: .destructive) {
                isShowingDeleteConfirmation = true
            }
        } preview: {
            SubscriberDetailsHeaderView(subscriber: viewModel.subscriber)
                .padding(.vertical)
        }
        .confirmationDialog(Strings.confirmDeleteTitle, isPresented: $isShowingDeleteConfirmation, actions: {
            Button(role: .destructive) {
                viewModel.delete()
            } label: {
                Text(Strings.delete)
            }
        }, message: {
            Text(String(format: Strings.confirmDeleteMessage, viewModel.title))
        })
        .opacity(viewModel.isDeleting ? 0.5 : 1)
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
final class SubscriberRowViewModel: @preconcurrency Identifiable {
    let subscriber: SubscribersServiceRemote.GetSubscribersResponse.Subscriber
    var id: Int { subscriberID }
    var subscriberID: Int { subscriber.subscriberID }

    let title: String
    let avatar: Avatar
    let details: String

    enum Avatar {
        case remote(URL?)
        case email
    }

    @Published private(set) var isDeleting = false

    private let blog: SubscribersBlog

    init(blog: SubscribersBlog, subscriber: SubscribersServiceRemote.GetSubscribersResponse.Subscriber) {
        self.blog = blog
        self.subscriber = subscriber

        if subscriber.dotComUserID == 0 {
            self.avatar = .email
        } else {
            self.avatar = .remote(subscriber.avatar.flatMap(URL.init))
        }
        self.title = subscriber.displayName ?? subscriber.emailAddress ?? ""
        self.details = subscriber.dateSubscribed.toShortString()
    }

    func makeDetailsViewModel() -> SubscriberDetailsViewModel {
        SubscriberDetailsViewModel(blog: blog, subscriber: subscriber)
    }

    func delete() {
        isDeleting = true
        Task {
            do {
                try await blog.makeSubscribersService()
                    .deleteSubscriber(subscriber, siteID: blog.dotComSiteID)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                Notice(error: error).post()
                isDeleting = false
            }
        }
    }
}

extension Foundation.Notification.Name {
    @MainActor
    static let subscriberDeleted = Foundation.Notification.Name("subscriberDeleted")
}

private enum Strings {
    static let delete = NSLocalizedString("subscribers.buttonDeleteSubscriber", value: "Delete Subscriber", comment: "Button title")
    static let confirmDeleteTitle = NSLocalizedString("subscribers.deleteSubscriberConfirmationDialog.title", value: "Delete the subscriber", comment: "Remove subscriber confirmation dialog title")
    static let confirmDeleteMessage = NSLocalizedString("subscribers.deleteSubscriberConfirmationDialog.message", value: "Are you sure you want to remove %@? They will no longer receive new notifications from your site.", comment: "Remove subscriber confirmation dialog message; subscriber name as input.")
}

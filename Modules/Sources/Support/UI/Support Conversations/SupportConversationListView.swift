import SwiftUI

@MainActor
public struct SupportConversationListView: View {

    enum ViewState: Equatable {
        case start
        case loading(Task<Void, Never>)
        case partiallyLoaded([ConversationSummary], Task<Void, Never>)
        case loaded([ConversationSummary])
        case error(String)

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else {
                return false
            }

            return true
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    private var state: ViewState = .start

    @State
    private var isComposingNewMessage: Bool = false

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        Group {
            switch self.state {
            case .start, .loading:
                FullScreenProgressView(Localization.loadingConversations)
            case .partiallyLoaded(let conversations, _), .loaded(let conversations):
                self.conversationsList(conversations)
            case .error(let error):
                FullScreenErrorView(
                    title: Localization.errorLoadingSupportConversations,
                    message: error
                )
            }
        }
        .navigationTitle(Localization.supportConversations)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.isComposingNewMessage = true
                }
                label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: self.$isComposingNewMessage, content: {
            NavigationStack {
                SupportForm(supportIdentity: self.currentUser) {
                    self.reloadConversations()
                }
            }.environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        })
        .overlay {
            OverlayProgressView(shouldBeVisible: self.state.isPartiallyLoaded)
        }
        .onAppear {
            self.dataProvider.userDid(.viewSupportTicketList)
        }
        .task(self.loadConversations)
        .refreshable(action: self.reloadConversations)
    }

    @ViewBuilder
    func conversationsList(_ conversations: [ConversationSummary]) -> some View {
        List {
            ForEach(conversations) { conversation in
                NavigationLink {
                    SupportConversationView(
                        conversation: conversation,
                        currentUser: currentUser
                    ).environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller

                } label: {
                    EmailRowView(conversation: conversation)
                }
            }
        }
        .listStyle(PlainListStyle())
        .listRowInsets(.zero)
        .listRowSeparator(.hidden)
    }

    @MainActor
    private func loadConversations() {
        guard case .start = self.state else {
            return
        }

        self.state = .loading(self.cacheTask)
    }

    @MainActor
    private func reloadConversations() {
        guard case .loaded(let conversations) = state else {
            return
        }

        self.state = .partiallyLoaded(conversations, self.fetchTask)
    }

    private var cacheTask: Task<Void, Never> {
        Task {
            do {
                let fetch = try dataProvider.loadSupportConversations()

                if let cachedResults = try await fetch.cachedResult() {
                    self.state = .partiallyLoaded(cachedResults, self.fetchTask)
                }

                let fetchedResults = try await fetch.fetchedResult()
                self.state = .loaded(fetchedResults)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    private var fetchTask: Task<Void, Never> {
        Task {
            do {
                let fetch = try dataProvider.loadSupportConversations()
                let conversations = try await fetch.fetchedResult()
                self.state = .loaded(conversations)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}

// MARK: - Email Row View
struct EmailRowView: View {

    @Environment(\.sizeCategory)
    private var sizeCategory

    let conversation: ConversationSummary

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                header

                HStack {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        Text(formatTimestamp(conversation.lastMessageSentAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }.padding(.bottom, 2)

            Text(conversation.plainTextDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    var header: some View {
        if self.sizeCategory.isAccessibilityCategory {
            VStack {
                HStack {
                    Text(conversation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Spacer()
                }

                HStack {
                    ChipView(
                        string: conversation.status.title,
                        color: conversation.status.color
                    ).controlSize(.mini)
                    Spacer()
                }
            }
        } else {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                ChipView(
                    string: conversation.status.title,
                    color: conversation.status.color
                ).controlSize(.mini)
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        SupportConversationListView(
            currentUser: SupportDataProvider.supportUser
        )
    }.environmentObject(SupportDataProvider.testing)
}

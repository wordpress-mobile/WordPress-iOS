import SwiftUI

public struct SupportConversationListView: View {

    enum ViewState: Equatable {
        case loading
        case partiallyLoaded([ConversationSummary])
        case loaded([ConversationSummary])
        case error(Error)

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.partiallyLoaded(let lhsConversations), .partiallyLoaded(let rhsConversations)):
                return lhsConversations == rhsConversations
            case (.loaded(let lhsConversations), .loaded(let rhsConversations)):
                return lhsConversations == rhsConversations
            case (.error, .error):
                return true
            default:
                return false
            }
        }

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
    private var state: ViewState = .loading

    @State
    private var isComposingNewMessage: Bool = false

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        Group {
            switch self.state {
            case .loading:
                ProgressView(Localization.loadingConversations)
            case .partiallyLoaded(let conversations), .loaded(let conversations):
                self.conversationsList(conversations)
            case .error(let error):
                ErrorView(
                    title: Localization.errorLoadingSupportConversations,
                    message: error.localizedDescription
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
                SupportForm(supportIdentity: self.currentUser)
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

    private func loadConversations() async {
        do {
            let fetch = try dataProvider.loadSupportConversations()

            if let cachedResults = try await fetch.cachedResult() {
                await MainActor.run {
                    self.state = .partiallyLoaded(cachedResults)
                }
            }

            let fetchedResults = try await fetch.fetchedResult()

            await MainActor.run {
                self.state = .loaded(fetchedResults)
            }
        } catch {
            await MainActor.run {
                self.state = .error(error)
            }
        }
    }

    private func reloadConversations() async {
        do {
            let conversations = try await dataProvider.loadSupportConversations().fetchedResult()

            await MainActor.run {
                self.state = .loaded(conversations)
            }
        } catch {
            await MainActor.run {
                self.state = .error(error)
            }
        }
    }
}

// MARK: - Email Row View
struct EmailRowView: View {
    let conversation: ConversationSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 4) {
                    Text(formatTimestamp(conversation.lastMessageSentAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }.padding(.bottom, 4)

            Text(conversation.plainTextDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.clear)
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

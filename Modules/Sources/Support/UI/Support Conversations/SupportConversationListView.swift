import SwiftUI

public struct SupportConversationListView: View {

    enum ViewState {
        case loading
        case loaded([ConversationSummary])
        case error(Error)
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
            case .loaded(let conversations): self.conversationsList(conversations)
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
            NavigationView {
                SupportForm(supportIdentity: self.currentUser)
            }.environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        })
        .task(self.loadConversations)
        .refreshable(action: self.loadConversations)
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
            let conversations = try await dataProvider.loadSupportConversations()

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
    NavigationView {
        SupportConversationListView(
            currentUser: SupportDataProvider.supportUser
        )
    }.environmentObject(SupportDataProvider.testing)
}

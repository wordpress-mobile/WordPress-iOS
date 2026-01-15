import SwiftUI

@MainActor
public final class UnifiedConversationViewModel: ObservableObject {

    private let dataProvider: SupportDataProvider

    let currentUser: SupportUser

    @Published
    var title: String?

    @Published
    var messages: [SupportMessage] = []

    @Published
    var compositionIsDisabled: Bool = true

    @Published
    var isComposingReply: Bool = false

    @Published
    var isLoadingData: Bool = true

    @Published
    var isReloadingData: Bool = false

    @Published
    var loadingError: Error?

    @Published
    var inFlightMessage: String?

    public init(
        supportUser: SupportUser,
        dataProvider: SupportDataProvider
    ) {
        self.currentUser = supportUser
        self.dataProvider = dataProvider
    }

    public func loadConversation(id: UInt64) async {
        debugPrint("Loading conversation \(id)")
        do {
            let conversation = try await self.dataProvider.loadUnifiedConversation(id: id)

            if let cachedResult = try await conversation.cachedResult() {
                self.title = cachedResult.title
                self.messages = cachedResult.messages

                self.isLoadingData = false
                self.isReloadingData = true
            }

            let fetchedResult = try await conversation.fetchedResult()

            self.title = fetchedResult.title
            self.messages = fetchedResult.messages
            debugPrint("Set title: \(fetchedResult.title)")
            debugPrint("Set messages: \(fetchedResult.messages.count)")

            self.isLoadingData = false
            self.isReloadingData = false
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    public func sendMessage(_ message: String) {
        self.inFlightMessage = message
//
//        Task {
//
//        }
    }
}

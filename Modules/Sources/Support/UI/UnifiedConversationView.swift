import SwiftUI

struct UnifiedConversationView: View {

    private let conversationId: UInt64

    @ObservedObject
    var viewModel: UnifiedConversationViewModel

    @ScaledMetric(relativeTo: .title)
    var bottomSpacerHeight: CGFloat = 64

    @Namespace
    var bottom

    init(
        currentUser: SupportUser,
        conversationId: UInt64,
        dataProvider: SupportDataProvider
    ) {
        self.conversationId = conversationId
        self.viewModel = UnifiedConversationViewModel(
            supportUser: currentUser,
            dataProvider: dataProvider
        )
    }

    var body: some View {
        ZStack {
            if viewModel.isLoadingData {
                if let error  = viewModel.loadingError {
                    ErrorView(
                        title: "Error Loading Conversation",
                        message: error.localizedDescription,
                        systemImage: "exclamationmark.triangle"
                    )
                } else {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView("Loading Conversation")
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            else {
                ScrollView {
                    VStack {
                        ConversationBotIntro(currentUser: viewModel.currentUser)
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.bottom)

                        ForEach(viewModel.messages.botMessages() ) { message in
                            MessageView(message: message).id(message.id)
                        }

                        if let inFlightMessage = viewModel.inFlightMessage {
                            MessageView(
                                message: BotMessage(
                                    id: .max,
                                    text: inFlightMessage,
                                    date: Date(),
                                    userWantsToTalkToHuman: false,
                                    isWrittenByUser: true
                                )
                            )
                        }

                        if viewModel.messages.transferredToSupportMessage() != nil {
                            SystemMessageView(message: "Transferred to human support")
                                .padding(.vertical)
                        }

                        ForEach(viewModel.messages.supportMessages()) { message in
                            SupportConversationMessageView(message: message)
                        }

                        Text("").padding(.bottom, bottomSpacerHeight)
                            .listRowInsets(.zero)
                            .listRowBackground(Color.clear)
                            .listRowSpacing(0)
                            .id(self.bottom)
                    }
                }
                VStack {
                    Spacer()

                    if true {
                        Button {
                            self.viewModel.isComposingReply.toggle()
                        } label: {
                            Spacer()
                            HStack(alignment: .firstTextBaseline) {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text(Localization.reply)
                            }.padding(.vertical, 8)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(self.viewModel.compositionIsDisabled)
                    } else {
                        CompositionView(
                            isDisabled: viewModel.compositionIsDisabled,
                            action: viewModel.sendMessage
                        )
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(self.viewModel.title ?? "Conversation")
        .task {
            await self.viewModel.loadConversation(id: self.conversationId)
        }
    }
}

#Preview {
    let currentUser = SupportUser(
        userId: 0,
        username: "example",
        email: "test@example.com"
    )

    NavigationStack {
        UnifiedConversationView(
            currentUser: currentUser,
            conversationId: 42,
            dataProvider: SupportDataProvider.testing
        )
    }
}

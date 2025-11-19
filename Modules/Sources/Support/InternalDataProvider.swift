import Foundation
import AVFoundation
import AsyncImageKit
import WordPressCoreProtocols

// This file is all module-internal and provides sample data for UI development

extension SupportDataProvider {
    static let testing = SupportDataProvider(
        applicationLogProvider: InternalLogDataProvider(),
        botConversationDataProvider: InternalBotConversationDataProvider(),
        userDataProvider: InternalUserDataProvider(),
        supportConversationDataProvider: InternalSupportConversationDataProvider(),
        diagnosticsDataProvider: InternalDiagnosticsDataProvider(),
        mediaHost: InternalMediaHost()
    )

    static let applicationLog = ApplicationLog(path: URL(filePath: #filePath), createdAt: Date(), modifiedAt: Date())
    static let supportUser = SupportUser(
        userId: 1234,
        username: "demo-user",
        email: "test@example.com",
        permissions: [.createChatConversation, .createSupportRequest]
    )
    static let botConversation = BotConversation(
        id: 1234,
        title: "App Crashing on Launch",
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        messages: [
            BotMessage(
                id: 1001,
                text: "Hi, I'm having trouble with the app. It keeps crashing when I try to open it after the latest update. Can you help?",
                date: Date().addingTimeInterval(-3600), // 1 hour ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ),
            BotMessage(
                id: 1002,
                text: "I'm sorry to hear you're experiencing crashes! I'd be happy to help you troubleshoot this issue. Let me ask a few questions to better understand what's happening. What device are you using and what iOS version are you running?",
                date: Date().addingTimeInterval(-3540), // 59 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: false
            ),
            BotMessage(
                id: 1003,
                text: "I'm using an iPhone 14 Pro with iOS 17.5. The app worked fine before the update yesterday.",
                date: Date().addingTimeInterval(-3480), // 58 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ),
            BotMessage(
                id: 1004,
                text: "Thank you for that information! iOS 17.5 on iPhone 14 Pro should work well with our latest update. Let's try a few troubleshooting steps:\n\n1. First, try force-closing the app and reopening it\n2. If that doesn't work, try restarting your iPhone\n3. As a last resort, you might need to delete and reinstall the app\n\nCan you try step 1 first and let me know if that helps?",
                date: Date().addingTimeInterval(-3420), // 57 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: false
            ),
            BotMessage(
                id: 1005,
                text: "I tried force-closing and restarting my phone, but it's still crashing immediately when I tap the app icon. Should I try reinstalling?",
                date: Date().addingTimeInterval(-3300), // 55 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ),
            BotMessage(
                id: 1006,
                text: "Yes, let's try reinstalling the app. This will often resolve issues caused by corrupted app data during updates. Here's what to do:\n\n1. Press and hold the app icon until it jiggles\n2. Tap the X to delete it\n3. Go to the App Store and reinstall the app\n4. Sign back into your account\n\nYour data should be preserved if you're signed into your account. Give this a try and let me know how it goes!",
                date: Date().addingTimeInterval(-3240), // 54 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: false
            ),
            BotMessage(
                id: 1007,
                text: "That worked! The app is opening normally now. Thank you so much for your help!",
                date: Date().addingTimeInterval(-180), // 3 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ),
            BotMessage(
                id: 1008,
                text: "Wonderful! I'm so glad that resolved the issue for you. The reinstall process often fixes problems that occur during app updates. If you run into any other issues, please don't hesitate to reach out. Is there anything else I can help you with today?",
                date: Date().addingTimeInterval(-120), // 2 minutes ago
                userWantsToTalkToHuman: false,
                isWrittenByUser: false
            )
        ])

    static var conversationReferredToHuman: BotConversation {
        BotConversation(
            id: 5678,
            title: "App Crashing on Launch",
            createdAt: Date().addingTimeInterval(-60), // 1 minute ago
            messages: botConversation.messages + [
                BotMessage(
                    id: 1009,
                    text: "Can I please talk to a human?",
                    date: Date().addingTimeInterval(-60), // 1 minute ago
                    userWantsToTalkToHuman: false,
                    isWrittenByUser: true
                ),
                BotMessage(
                    id: 1010,
                    text: "I understand you'd prefer to speak with a human support agent. You can easily escalate this to our support team.",
                    date: Date(),
                    userWantsToTalkToHuman: true,
                    isWrittenByUser: false
                )
        ])
    }

    static let supportConversationSummaries: [ConversationSummary] = [
        ConversationSummary(
            id: 1,
            title: "Login Issues with Two-Factor Authentication",
            description: "I'm having trouble logging into my account. The two-factor authentication code isn't working properly and I keep getting locked out.",
            status: .waitingForSupport,
            lastMessageSentAt: Date().addingTimeInterval(-300) // 5 minutes ago
        ),
        ConversationSummary(
            id: 2,
            title: "Billing Question - Duplicate Charges",
            description: "I noticed duplicate charges on my credit card statement for this month's subscription. Can you help me understand what happened?",
            status: .waitingForUser,
            lastMessageSentAt: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
        ConversationSummary(
            id: 3,
            title: "Feature Request: Dark Mode Support",
            description: "Would it be possible to add dark mode support to the mobile app? Many users in our team have been requesting this feature.",
            status: .resolved,
            lastMessageSentAt: Date().addingTimeInterval(-86400) // 1 day ago
        ),
        ConversationSummary(
            id: 4,
            title: "Data Export Not Working",
            description: "I'm trying to export my data but the process keeps failing at 50%. Is there a known issue with large datasets?",
            status: .resolved,
            lastMessageSentAt: Date().addingTimeInterval(-172800) // 2 days ago
        ),
        ConversationSummary(
            id: 5,
            title: "Account Migration Assistance",
            description: "I need help migrating my old account to the new system. I have several years of data that I don't want to lose.",
            status: .resolved,
            lastMessageSentAt: Date().addingTimeInterval(-259200) // 3 days ago
        ),
        ConversationSummary(
            id: 6,
            title: "API Rate Limiting Questions",
            description: "Our application is hitting rate limits frequently. Can we discuss increasing our API quota or optimizing our usage patterns?",
            status: .closed,
            lastMessageSentAt: Date().addingTimeInterval(-604800) // 1 week ago
        ),
        ConversationSummary(
            id: 7,
            title: "Security Concern - Suspicious Activity",
            description: "I received an email about suspicious activity on my account. I want to make sure my account is secure and review recent access logs.",
            status: .closed,
            lastMessageSentAt: Date().addingTimeInterval(-1209600) // 2 weeks ago
        ),
        ConversationSummary(
            id: 8,
            title: "Integration Help with Webhook Setup",
            description: "I'm having trouble setting up webhooks for our CRM integration. The endpoints aren't receiving the expected payload format.",
            status: .closed,
            lastMessageSentAt: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
    ]

    static let supportConversation = Conversation(
        id: 1,
        title: "Issue with app crashes",
        description: "The app keeps crashing when I try to upload photos. This has been happening for the past week and is very frustrating.",
        lastMessageSentAt: Date().addingTimeInterval(-2400),
        status: .closed,
        messages: [
            Message(
                id: 1,
                content: "Hello! I'm having trouble with the app crashing when I try to upload photos. Can you help?",
                createdAt: Date().addingTimeInterval(-3600),
                authorName: "Test User",
                authorIsUser: true,
                attachments: []
            ),
            Message(
                id: 2,
                content: "Hi there! I'm sorry to hear you're experiencing crashes. Let me help you troubleshoot this issue. Can you tell me what device you're using and what version of the app?",
                createdAt: Date().addingTimeInterval(-3000),
                authorName: "Support Engineer Alice",
                authorIsUser: false,
                attachments: []
            ),
            Message(
                id: 3,
                content: "I'm using an iPhone 14 Pro with iOS 17.1 and the latest version of the app from the App Store. The crashes seem to happen right after I tap the Upload button and pick a photo from my library.",
                createdAt: Date().addingTimeInterval(-2400),
                authorName: "Test User",
                authorIsUser: true,
                attachments: []
            )
            ,
            Message(
                id: 4,
                content: "Understood. Do you notice this with any photo, or only certain ones (for example, very large HEIF images or Live Photos)?",
                createdAt: Date().addingTimeInterval(-1950),
                authorName: "Support Engineer Alice",
                authorIsUser: false,
                attachments: []
            ),
            Message(
                id: 5,
                content: "It happens mostly with Live Photos. Regular photos sometimes work.",
                createdAt: Date().addingTimeInterval(-1800),
                authorName: "Test User",
                authorIsUser: true,
                attachments: [
                    Attachment(
                        id: 1234,
                        filename: "sample-1234.jpg",
                        contentType: "application/jpeg",
                        fileSize: 1234,
                        url: URL(string: "https://picsum.photos/seed/1/800/600")!
                    )
                ]
            ),
            Message(
                id: 6,
                content: "Thanks, that helps. We recently fixed an issue with Live Photo processing. Could you try disabling Live Photo upload in Settings > Upload Options and try again?",
                createdAt: Date().addingTimeInterval(-1650),
                authorName: "Support Engineer Alice",
                authorIsUser: false,
                attachments: []
            ),
            Message(
                id: 7,
                content: "I disabled Live Photo upload and the app no longer crashes. Upload works now!",
                createdAt: Date().addingTimeInterval(-1500),
                authorName: "Test User",
                authorIsUser: true,
                attachments: []
            ),
            Message(
                id: 8,
                content: "Great to hear! We'll include the fix in the next update so Live Photos work without disabling. In the meantime, you can keep that setting off. Anything else I can help with?",
                createdAt: Date().addingTimeInterval(-1350),
                authorName: "Support Engineer Alice",
                authorIsUser: false,
                attachments: []
            ),
            Message(
                id: 9,
                content: "No, that's all. Thanks for the quick help!",
                createdAt: Date().addingTimeInterval(-1200),
                authorName: "Test User",
                authorIsUser: true,
                attachments: []
            )
        ]
    )

}

actor InternalLogDataProvider: ApplicationLogDataProvider {
    private var logs: [ApplicationLog] = [
        ApplicationLog(path: URL(filePath: #filePath), createdAt: Date(), modifiedAt: Date()),
        ApplicationLog(path: URL(filePath: #filePath).deletingLastPathComponent().appendingPathComponent("SupportDataProvider.swift"), createdAt: Date(), modifiedAt: Date()),
    ]

    func fetchApplicationLogs() async throws -> [ApplicationLog] {
        if Bool.random() {
            return self.logs
        } else {
            throw CocoaError(.fileNoSuchFile)
        }
    }

    func deleteApplicationLogs(in logs: [ApplicationLog]) async throws {
        for log in logs {
            guard let index = self.logs.firstIndex(where: { $0.id == log.id }) else {
                return
            }

            self.logs.remove(at: index)
        }
    }

    func deleteAllApplicationLogs() async throws {
        self.logs = []
    }
}

actor InternalBotConversationDataProvider: BotConversationDataProvider {
    func loadIdentity() async throws -> SupportUser? {
        await SupportDataProvider.supportUser
    }

    nonisolated func loadBotConversations() throws -> any CachedAndFetchedResult<[BotConversation]> {
        UncachedResult {
            [await SupportDataProvider.botConversation]
        }
    }

    nonisolated func loadBotConversation(id: UInt64) throws -> any CachedAndFetchedResult<BotConversation> {
        UncachedResult {
            if id == 5678 {
                return await SupportDataProvider.conversationReferredToHuman
            }

            return await SupportDataProvider.botConversation
        }
    }

    func delete(conversationIds: [UInt64]) async throws {
        // TODO
    }

    func sendMessage(message: String, in conversation: BotConversation?) async throws -> BotConversation {
        try await Task.sleep(for: .seconds(8))
        return conversation!.appending(messages: [
            BotMessage(
                id: 1100,
                text: message,
                date: Date(),
                userWantsToTalkToHuman: false,
                isWrittenByUser: true
            ),
            BotMessage(
                id: 1200,
                text: "Thanks – I've noted that down.",
                date: Date(),
                userWantsToTalkToHuman: false,
                isWrittenByUser: false
            )
        ])
    }
}

actor InternalUserDataProvider: CurrentUserDataProvider {
    nonisolated func fetchCurrentSupportUser() throws -> any CachedAndFetchedResult<SupportUser> {
        UncachedResult {
            await SupportDataProvider.supportUser
        }
    }
}

actor InternalSupportConversationDataProvider: SupportConversationDataProvider {
    let maximumUploadSize: UInt64 = 5_000_000 // 5MB

    private var conversations: [UInt64: Conversation] = [:]

    nonisolated func loadSupportConversations() throws -> any CachedAndFetchedResult<[ConversationSummary]> {
        UncachedResult {
            return await SupportDataProvider.supportConversationSummaries
        }
    }

    nonisolated func loadSupportConversation(id: UInt64) throws -> any CachedAndFetchedResult<Conversation> {
        UncachedResult {
            let conversation = await SupportDataProvider.supportConversation
            await self.cache(conversation)
            return conversation
        }
    }

    func replyToSupportConversation(
        id: UInt64,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {

        let conversation = try await loadSupportConversation(id: id).fetchedResult()

        if Bool.random() {
            throw CocoaError(.validationInvalidDate)
        }

        let newMessage = Message(
            id: UInt64.random(in: 0...UInt64.max),
            content: message,
            createdAt: Date(),
            authorName: user.username,
            authorIsUser: true,
            attachments: [] // TODO
        )

        try await Task.sleep(for: .seconds(3))
        return conversation.addingMessage(newMessage)
    }

    func createSupportConversation(
        subject: String,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        return Conversation(
            id: 9999,
            title: subject,
            description: message,
            lastMessageSentAt: Date(),
            status: .waitingForSupport,
            messages: [Message(
                id: 1234,
                content: message,
                createdAt: Date(),
                authorName: user.username,
                authorIsUser: true,
                attachments: []
            )]
        )
    }

    private func cache(_ value: Conversation) {
        self.conversations[value.id] = value
    }
}

actor InternalDiagnosticsDataProvider: DiagnosticsDataProvider {

    private var didClear: Bool = false

    func fetchDiskCacheUsage() async throws -> WordPressCoreProtocols.DiskCacheUsage {
        if didClear {
            DiskCacheUsage(fileCount: 0, byteCount: 0)
        } else {
            DiskCacheUsage(fileCount: 64, byteCount: 623_423_562)
        }
    }

    func clearDiskCache(progress: @Sendable (CacheDeletionProgress) async throws -> Void) async throws {
        let totalFiles = 12

        // Initial progress (0%)
        try await progress(CacheDeletionProgress(filesDeleted: 0, totalFileCount: totalFiles))

        for i in 1...totalFiles {
            // Pretend each file takes a short time to delete
            try await Task.sleep(for: .milliseconds(150))

            // Report incremental progress
            try await progress(CacheDeletionProgress(filesDeleted: i, totalFileCount: totalFiles))
        }

        self.didClear = true
    }
}

actor InternalMediaHost: MediaHostProtocol {
    func authenticatedRequest(for url: URL) async throws -> URLRequest {
        if Bool.random() {
            throw CocoaError(.coderInvalidValue)
        }

        return URLRequest(url: url)
    }

    func authenticatedAsset(for url: URL) async throws -> AVURLAsset {
        if Bool.random() {
            throw CocoaError(.coderInvalidValue)
        }

        return AVURLAsset(url: url)
    }
}

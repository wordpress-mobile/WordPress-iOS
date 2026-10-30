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
}

actor InternalLogDataProvider: ApplicationLogDataProvider {
    /// The logs are made up here, so there's nothing to keep from anyone.
    nonisolated var canShareApplicationLogs: Bool {
        true
    }

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

import Testing
import Foundation
import WordPressCore

@Suite(.serialized)
struct PluginRecommendationServiceTests {
    let service: PluginRecommendationService

    init() async {
        self.service = PluginRecommendationService(userDefaults: UserDefaults())
        await self.service.resetRecommendations()
    }

    @Test func `test recommendations should always be shown if none have been shown before`() async throws {
        #expect(await service.shouldRecommendPlugin(for: .themeStyles, frequency: .monthly))
    }

    @Test func `test recommendations shouldn't be shown if they have been shown within the given frequency`() async throws {
        await service.didRecommendPlugin(for: .themeStyles)
        #expect(await service.shouldRecommendPlugin(for: .themeStyles, frequency: .daily) == false)
    }

    @Test func `test recommendations should be shown again once the cooldown period has passed`() async throws {
        await service.didRecommendPlugin(for: .themeStyles, at: Date().addingTimeInterval(-100_000))
        #expect(await service.shouldRecommendPlugin(for: .themeStyles, frequency: .daily))
    }

    @Test func `test recommendations can be reset`() async throws {
        await service.didRecommendPlugin(for: .themeStyles)
        await service.resetRecommendations()
        #expect(await service.shouldRecommendPlugin(for: .themeStyles, frequency: .daily))
    }

    @Test func `test that only one notification type is shown per day`() async throws {
        await service.didRecommendPlugin(for: .themeStyles)
        #expect(await service.shouldRecommendPlugin(for: .editorCompatibility, frequency: .daily) == false)
    }
}

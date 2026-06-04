import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class BloggingPromptsServiceRemoteTests: RemoteTestCase, RESTTestable {

    private let siteID = NSNumber(value: 1)

    var mockApi: WordPressComRestApi!
    var service: BloggingPromptsServiceRemote!

    // MARK: Setup

    override func setUp() {
        super.setUp()

        mockApi = getRestApi()
        service = BloggingPromptsServiceRemote(wordPressComRestApi: mockApi)
    }

    override func tearDown() {
        super.tearDown()

        mockApi = nil
        service = nil
    }

    // MARK: Tests

    func test_fetchSettings_returnsRemoteSettings() {
        stubRemoteResponse(
            .bloggingPromptsEndpoint,
            filename: .mockFetchSettingsFilename,
            contentType: .ApplicationJSON
        )

        let expect = expectation(description: "Fetch blogging prompts settings succeeded")
        service.fetchSettings(for: siteID) { result in
            guard case .success(let settings) = result else {
                XCTFail("Expected success result type")
                return
            }

            XCTAssertTrue(settings.promptCardEnabled)
            XCTAssertTrue(settings.promptRemindersEnabled)

            // reminder days
            XCTAssertFalse(settings.reminderDays.monday)
            XCTAssertTrue(settings.reminderDays.tuesday)
            XCTAssertFalse(settings.reminderDays.wednesday)
            XCTAssertTrue(settings.reminderDays.thursday)
            XCTAssertFalse(settings.reminderDays.friday)
            XCTAssertTrue(settings.reminderDays.saturday)
            XCTAssertFalse(settings.reminderDays.sunday)

            XCTAssertEqual(settings.reminderTime, "14.30")
            XCTAssertEqual(settings.isPotentialBloggingSite, true)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }

    func test_updateSettings_withUpdatedFields_returnsUpdatedSettings() {
        let updatedSettings = makeSettings()
        stubRemoteResponse(
            .bloggingPromptsEndpoint,
            filename: .mockUpdateSettingsReturningObjectFilename,
            contentType: .ApplicationJSON
        )

        let expect = expectation(description: "Update blogging prompts settings succeeded")
        service.updateSettings(for: siteID, with: updatedSettings) { result in
            guard case .success(let settings) = result else {
                XCTFail("Expected success result type")
                return
            }

            XCTAssertNotNil(settings)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }

    func test_updateSettings_withNoUpdatedFields_returnsNil() {
        let updatedSettings = makeSettings()
        stubRemoteResponse(
            .bloggingPromptsEndpoint,
            filename: .mockUpdateSettingsReturningEmptyFilename,
            contentType: .ApplicationJSON
        )

        let expect = expectation(description: "Update blogging prompts settings succeeded")
        service.updateSettings(for: siteID, with: updatedSettings) { result in
            guard case .success(let settings) = result else {
                XCTFail("Expected success result type")
                return
            }

            XCTAssertNil(settings)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }
}

// MARK: - Private Helpers

private extension BloggingPromptsServiceRemoteTests {

    func makeSettings() -> RemoteBloggingPromptsSettings {
        let reminderDays = RemoteBloggingPromptsSettings.ReminderDays(
            monday: true,
            tuesday: false,
            wednesday: true,
            thursday: false,
            friday: true,
            saturday: false,
            sunday: true
        )

        return .init(
            promptCardEnabled: false,
            promptRemindersEnabled: true,
            reminderDays: reminderDays,
            reminderTime: "12.59 UTC",
            isPotentialBloggingSite: true
        )
    }
}

private extension String {
    static let bloggingPromptsEndpoint = "sites/1/blogging-prompts"
    static let mockFetchSettingsFilename = "blogging-prompts-settings-fetch-success.json"
    static let mockUpdateSettingsReturningObjectFilename = "blogging-prompts-settings-update-with-response.json"
    static let mockUpdateSettingsReturningEmptyFilename = "blogging-prompts-settings-update-empty-response.json"
}

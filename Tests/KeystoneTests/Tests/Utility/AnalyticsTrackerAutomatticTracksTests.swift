import XCTest

import AutomatticTracks
@testable import WordPress
@testable import WordPressData

/// Checks the anonymous ID that the tracker passes to `TracksService`, which hands it to ExPlat.
/// ExPlat keeps an experiment group across sign-in only if its requests carry the ID the device
/// used before sign-in.
final class AnalyticsTrackerAutomatticTracksTests: XCTestCase {
    private var contextManager: ContextManager!
    private var savedExPlat: ExPlat?
    private var tracksService: TracksServiceSpy!
    private var savedDefaults: [String: Any?] = [:]

    private let defaultsKeys = [
        "TracksAnonymousUserID",
        "TracksLoggedInUserID",
        "TracksExperimentsAnonymousUserID"
    ]

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        savedExPlat = ExPlat.shared
        for key in defaultsKeys {
            savedDefaults[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        for (key, value) in savedDefaults {
            UserDefaults.standard.set(value, forKey: key)
        }
        ExPlat.shared = savedExPlat
        UserSettings.defaultDotComUUID = nil
        contextManager = nil
        super.tearDown()
    }

    func testExPlatKeepsTheSignedOutAnonymousIDAfterSignIn() throws {
        // Given a signed-out session
        makeTracker().beginSession()
        let anonymousID = try XCTUnwrap(UserDefaults.standard.string(forKey: "TracksAnonymousUserID"))
        XCTAssertEqual(tracksService.exPlatAnonymousID, anonymousID)

        // When the user signs in
        let tracker = makeTracker()
        tracker.beginSession()
        signIn()
        tracker.refreshMetadata()

        // Then Tracks drops the anonymous ID, but ExPlat still gets it
        XCTAssertNil(UserDefaults.standard.string(forKey: "TracksAnonymousUserID"))
        XCTAssertEqual(tracksService.exPlatAnonymousID, anonymousID)
    }

    func testExPlatKeepsTheSignedOutAnonymousIDAfterRelaunch() throws {
        // Given a sign-in from the signed-out state
        makeTracker().beginSession()
        let anonymousID = try XCTUnwrap(UserDefaults.standard.string(forKey: "TracksAnonymousUserID"))
        let tracker = makeTracker()
        tracker.beginSession()
        signIn()
        tracker.refreshMetadata()

        // When the app launches again
        makeTracker().beginSession()

        // Then
        XCTAssertEqual(tracksService.exPlatAnonymousID, anonymousID)
    }

    func testSignOutForgetsTheAnonymousIDKeptForExPlat() throws {
        // Given
        makeTracker().beginSession()
        let anonymousID = try XCTUnwrap(UserDefaults.standard.string(forKey: "TracksAnonymousUserID"))
        let tracker = makeTracker()
        tracker.beginSession()
        signIn()
        tracker.refreshMetadata()

        // When
        UserSettings.defaultDotComUUID = nil
        tracker.refreshMetadata()

        // Then ExPlat gets the new signed-out ID, and the old one is gone
        XCTAssertNil(UserDefaults.standard.string(forKey: "TracksExperimentsAnonymousUserID"))
        let newAnonymousID = try XCTUnwrap(UserDefaults.standard.string(forKey: "TracksAnonymousUserID"))
        XCTAssertEqual(tracksService.exPlatAnonymousID, newAnonymousID)
        XCTAssertNotEqual(newAnonymousID, anonymousID)
    }

    func testAccountSignedInBeforeTheUpdateSendsNoAnonymousID() {
        // Given an account that signed in before the ID was kept
        signIn()
        UserDefaults.standard.set("AnalyticsTrackerAutomatticTracksTests", forKey: "TracksLoggedInUserID")

        // When
        makeTracker().beginSession()

        // Then ExPlat assigns by account alone
        XCTAssertNil(tracksService.exPlatAnonymousID)
    }

    // MARK: - Helpers

    private func makeTracker() -> AnalyticsTrackerAutomatticTracks {
        AnalyticsTrackerAutomatticTracks(
            eventNamePrefix: "wpios",
            platform: "wpios",
            appURLScheme: "wordpress",
            makeTracksService: { [unowned self] contextManager in
                let service = TracksServiceSpy(contextManager: contextManager)!
                self.tracksService = service
                return service
            }
        )
    }

    private func signIn() {
        let account = AccountBuilder(contextManager.mainContext)
            .with(username: "AnalyticsTrackerAutomatticTracksTests")
            .build()
        UserSettings.defaultDotComUUID = account.uuid
    }
}

/// Records the anonymous ID the last session switch passed on to ExPlat.
private final class TracksServiceSpy: TracksService {
    private(set) var exPlatAnonymousID: String?

    override init!(contextManager: TracksContextManager!) {
        super.init(contextManager: contextManager)
        // Keep the event queue's timer from uploading to the network stubs of later tests.
        remoteCallsEnabled = false
    }

    override func switchToAnonymousUser(withAnonymousID anonymousID: String!) {
        super.switchToAnonymousUser(withAnonymousID: anonymousID)
        exPlatAnonymousID = anonymousID
    }

    override func switchToAuthenticatedUser(
        withUsername username: String!,
        userID: String!,
        anonymousID: String!,
        wpComToken token: String!,
        skipAliasEventCreation skipEvent: Bool
    ) {
        super
            .switchToAuthenticatedUser(
                withUsername: username,
                userID: userID,
                anonymousID: anonymousID,
                wpComToken: token,
                skipAliasEventCreation: skipEvent
            )
        exPlatAnonymousID = anonymousID
    }
}

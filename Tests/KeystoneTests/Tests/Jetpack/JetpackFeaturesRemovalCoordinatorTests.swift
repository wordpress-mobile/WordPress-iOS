import BuildSettingsKit
import Foundation
import Testing
import XCTest

@testable import WordPress

@Suite("JetpackFeaturesRemovalCoordinator")
struct JetpackFeaturesRemovalCoordinatorTests {

    // MARK: General Phase

    @Test("WordPress app with a WordPress.com account shows static screens")
    func wordPressWithDotComAccount() {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(app: .wordpress, hasDotComAccount: true)
        #expect(phase == .staticScreens)
    }

    @Test("WordPress app without a WordPress.com account shows the simplified UI")
    func wordPressWithoutDotComAccount() {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(app: .wordpress, hasDotComAccount: false)
        #expect(phase == .selfHosted)
    }

    @Test("Other apps show every feature", arguments: [AppBrand.jetpack, .reader], [true, false])
    func otherApps(app: AppBrand, hasDotComAccount: Bool) {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(app: app, hasDotComAccount: hasDotComAccount)
        #expect(phase == .normal)
    }

    @Test(
        "Phases map to the expected app UI",
        arguments: [
            (JetpackFeaturesRemovalCoordinator.GeneralPhase.normal, false, RootViewCoordinator.AppUIType.normal),
            (.normal, true, .normal),
            (.staticScreens, false, .staticScreens),
            (.staticScreens, true, .staticScreensWithReader),
            (.selfHosted, false, .simplified),
            (.selfHosted, true, .simplified)
        ]
    )
    func appUIType(
        phase: JetpackFeaturesRemovalCoordinator.GeneralPhase,
        isReaderInWordPressAppEnabled: Bool,
        expected: RootViewCoordinator.AppUIType
    ) {
        let appUIType = RootViewCoordinator.appUIType(
            for: phase,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
        #expect(appUIType == expected)
    }

    // MARK: Site Creation Phase

    @Test("WordPress app with a site shows the site creation overlay")
    func wordPressSiteCreationWithBlog() {
        let phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(app: .wordpress, hasBlog: true)
        #expect(phase == .two)
    }

    @Test("WordPress app without a site allows site creation")
    func wordPressSiteCreationWithoutBlog() {
        let phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(app: .wordpress, hasBlog: false)
        #expect(phase == .normal)
    }

    @Test("Other apps allow site creation", arguments: [AppBrand.jetpack, .reader], [true, false])
    func otherAppsSiteCreation(app: AppBrand, hasBlog: Bool) {
        let phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(app: app, hasBlog: hasBlog)
        #expect(phase == .normal)
    }
}

/// These tests set the shared `currentAppUIType`, so they run as XCTest rather than in parallel with Swift Testing.
final class JetpackFeaturesRemovalCoordinatorAppUITypeTests: XCTestCase {
    private var savedAppUIType: RootViewCoordinator.AppUIType?

    override func setUp() {
        super.setUp()
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
    }

    override func tearDown() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType
        super.tearDown()
    }

    func testStaticScreensWithReaderKeepsJetpackFeaturesDisabled() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader

        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderAvailable())
    }

    func testStaticScreensUIKeepsReaderUnavailable() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens

        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures())
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.isReaderAvailable())
    }
}

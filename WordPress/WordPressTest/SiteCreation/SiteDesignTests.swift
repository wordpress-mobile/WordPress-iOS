
import XCTest
@testable import WordPress

class SiteDesignTests: XCTestCase {
    private var remoteDesign: RemoteSiteDesign {
        let siteDesignPayload = "{\"slug\":\"alves\",\"title\":\"Alves\",\"segment_id\":1,\"categories\":[{\"slug\":\"business\",\"title\":\"Business\",\"description\":\"Business\",\"emoji\":\"💼\"}],\"demo_url\":\"https://public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/?language=en\",\"theme\":\"alves\",\"preview\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1600&w=800&h=1067\",\"preview_tablet\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1066&w=800&h=1067\",\"preview_mobile\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=400&vph=533&w=400&h=534\"}"
        return try! JSONDecoder().decode(RemoteSiteDesign.self, from: siteDesignPayload.data(using: .utf8)!)
    }

    func testSiteDesignPrimaryButtonTextNotLastStep() throws {

        // given
        let creator = SiteCreator()
        let siteDesignStep = SiteDesignStep(creator: creator, isLastStep: false)
        let expectedPrimaryTitle = "Choose"

        // when
        let siteDesignVC = try XCTUnwrap(siteDesignStep.content as? SiteDesignContentCollectionViewController)
        siteDesignVC.loadViewIfNeeded()
        siteDesignVC.viewDidLoad()

        // then
        let currentTitle = siteDesignVC.primaryActionButton.currentTitle
        XCTAssertEqual(expectedPrimaryTitle, currentTitle)
    }

    func testSiteDesignPrimaryButtonTextLastStep() throws {

        // given
        let creator = SiteCreator()
        let siteDesignStep = SiteDesignStep(creator: creator, isLastStep: true)
        let expectedPrimaryTitle = "Create Site"

        // when
        let siteDesignVC = try XCTUnwrap(siteDesignStep.content as? SiteDesignContentCollectionViewController)
        siteDesignVC.loadViewIfNeeded()
        siteDesignVC.viewDidLoad()

        // then
        let currentTitle = siteDesignVC.primaryActionButton.currentTitle
        XCTAssertEqual(expectedPrimaryTitle, currentTitle)
    }

    func testSiteDesignPreviewButtonTextNotLastStep() throws {

        // given
        let siteDesignPreviewVC = SiteDesignPreviewViewController(
            siteDesign: remoteDesign, selectedPreviewDevice: nil, createsSite: false, onDismissWithDeviceSelected: nil, completion: {design in })
        let expectedPrimaryTitle = "Choose"

        // when
        siteDesignPreviewVC.loadViewIfNeeded()
        siteDesignPreviewVC.viewDidLoad()

        // then
        let currentTitle = siteDesignPreviewVC.primaryActionButton.currentTitle
        XCTAssertEqual(expectedPrimaryTitle, currentTitle)
    }

    func testSiteDesignPreviewButtonTextLastStep() throws {

        // given
        let siteDesignPreviewVC = SiteDesignPreviewViewController(
            siteDesign: remoteDesign, selectedPreviewDevice: nil, createsSite: true, onDismissWithDeviceSelected: nil, completion: {design in })
        let expectedPrimaryTitle = "Create Site"

        // when
        siteDesignPreviewVC.loadViewIfNeeded()
        siteDesignPreviewVC.viewDidLoad()

        // then
        let currentTitle = siteDesignPreviewVC.primaryActionButton.currentTitle
        XCTAssertEqual(expectedPrimaryTitle, currentTitle)
    }

    /// Tests that the selected preview device cannot be changed from mobile
    func testSiteDesignPreviewDeviceIsAlwaysMobile() throws {

        // given
        let siteDesignVC = SiteDesignContentCollectionViewController(createsSite: false) { _ in }
        let expectedDevice = PreviewDeviceSelectionViewController.PreviewDevice.mobile
        XCTAssertEqual(siteDesignVC.selectedPreviewDevice, expectedDevice)

        // when
        siteDesignVC.selectedPreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice.tablet

        // then
        XCTAssertEqual(siteDesignVC.selectedPreviewDevice, expectedDevice)
    }
}

import Foundation
import CoreData
import Testing
import WordPressData
@testable import WordPress
@testable import WordPressMediaLibrary

@Suite("MediaTrackerAdapter upload events", .serialized)
@MainActor
struct MediaTrackerAdapterUploadEventsTests {
    let contextManager = ContextManager.forTesting()
    var mainContext: NSManagedObjectContext { contextManager.mainContext }

    private func makeAdapter() -> MediaTrackerAdapter {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        contextManager.saveContextAndWait(mainContext)
        return MediaTrackerAdapter(blog: blog, baseProperties: ["is_v2": "1"])
    }

    @Test("Photo from PHPicker maps to AddedPhotoViaDeviceLibrary")
    func photoLibraryImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .image))

        let events = TestAnalyticsTracker.tracked
        #expect(events.count == 1)
        #expect(events.first?.stat == .mediaLibraryAddedPhotoViaDeviceLibrary)
        #expect(events.first?.properties["media_origin"] as? String == "full_screen_picker")
        #expect(events.first?.properties["is_v2"] as? String == "1")
    }

    @Test("Video from PHPicker maps to AddedVideoViaDeviceLibrary")
    func photoLibraryVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .video))

        #expect(TestAnalyticsTracker.tracked.count == 1)
        #expect(TestAnalyticsTracker.tracked.first?.stat == .mediaLibraryAddedVideoViaDeviceLibrary)
    }

    @Test("Photo from camera maps to AddedPhotoViaCamera")
    func cameraImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .camera, kind: .image))

        #expect(TestAnalyticsTracker.tracked.count == 1)
        #expect(TestAnalyticsTracker.tracked.first?.stat == .mediaLibraryAddedPhotoViaCamera)
    }

    @Test("Video from camera maps to AddedVideoViaCamera")
    func cameraVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .camera, kind: .video))

        #expect(TestAnalyticsTracker.tracked.count == 1)
        #expect(TestAnalyticsTracker.tracked.first?.stat == .mediaLibraryAddedVideoViaCamera)
    }

    @Test("Photo from file picker maps to AddedPhotoViaOtherApps")
    func otherAppsImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .image))

        let events = TestAnalyticsTracker.tracked
        #expect(events.count == 1)
        #expect(events.first?.stat == .mediaLibraryAddedPhotoViaOtherApps)
        #expect(events.first?.properties["media_origin"] as? String == "document_picker")
        #expect(events.first?.properties["is_v2"] as? String == "1")
    }

    @Test("Video from file picker maps to AddedVideoViaOtherApps")
    func otherAppsVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .video))

        #expect(TestAnalyticsTracker.tracked.count == 1)
        #expect(TestAnalyticsTracker.tracked.first?.stat == .mediaLibraryAddedVideoViaOtherApps)
    }

    @Test("Document is silently dropped")
    func documentDropped() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .document))

        #expect(TestAnalyticsTracker.tracked.isEmpty)
    }

    @Test("Audio is silently dropped")
    func audioDropped() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .audio))

        #expect(TestAnalyticsTracker.tracked.isEmpty)
    }

    @Test("Retry maps to mediaLibraryUploadMediaRetried")
    func retryEvent() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryUploadRetried)

        let events = TestAnalyticsTracker.tracked
        #expect(events.count == 1)
        #expect(events.first?.stat == .mediaLibraryUploadMediaRetried)
        #expect(events.first?.properties["is_v2"] as? String == "1")
    }

    @Test("Stock Photos image fires PhotoViaStockPhotos + StockMediaUploaded")
    func stockPhotos_imageAdded_firesPhotoViaStockPhotos_andStockMediaUploaded() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .stockPhotos, kind: .image))

        let events = TestAnalyticsTracker.tracked
        #expect(events.contains { $0.stat == .mediaLibraryAddedPhotoViaStockPhotos })
        #expect(events.contains { $0.stat == .stockMediaUploaded })
        let photoViaEvent = events.first { $0.stat == .mediaLibraryAddedPhotoViaStockPhotos }
        #expect(photoViaEvent?.properties["is_v2"] as? String == "1")
        #expect(photoViaEvent?.properties["media_origin"] as? String == "full_screen_picker")
    }

    @Test("Stock Photos non-image kinds fire no external-source events")
    func stockPhotos_videoAdded_doesNotFireExternalSourceEvents() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        contextManager.saveContextAndWait(mainContext)
        let adapter = MediaTrackerAdapter(blog: blog, baseProperties: [:])
        adapter.track(.mediaLibraryAdded(source: .stockPhotos, kind: .video))

        let trackedStats = TestAnalyticsTracker.tracked.map(\.stat)
        #expect(!trackedStats.contains(.stockMediaUploaded))
        #expect(!trackedStats.contains(.mediaLibraryAddedPhotoViaStockPhotos))
    }

    @Test("Image Playground image fires no added-photo event")
    func imagePlayground_imageAdded_firesNoAddedPhotoEvent() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        contextManager.saveContextAndWait(mainContext)
        let adapter = MediaTrackerAdapter(blog: blog, baseProperties: [:])
        adapter.track(.mediaLibraryAdded(source: .imagePlayground, kind: .image))

        #expect(TestAnalyticsTracker.tracked.isEmpty)
    }
}

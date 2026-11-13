import Foundation
import Testing
@testable import AsyncImageKit

struct ImageSaliencyServiceTests {
    private let diskURL = FileManager.default.temporaryDirectory
        .appending(path: "saliency-\(UUID().uuidString).json")

    @Test func resultStoredBeforeDiskLoadIsNotEvictedFirst() async throws {
        defer { try? FileManager.default.removeItem(at: diskURL) }

        // GIVEN a full cache on disk
        var onDisk: [String: CGRect?] = [:]
        for index in 0..<1000 {
            onDisk["https://disk.example/\(index)"] = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        try JSONEncoder().encode(onDisk).write(to: diskURL)

        // WHEN a result is detected at launch, before the disk load finishes
        let service = ImageSaliencyService(diskURL: diskURL)
        let fresh = try #require(URL(string: "https://example.com/\(UUID().uuidString).jpg"))
        service.storeResult(CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), for: fresh)
        try await waitForDiskLoad(of: service, probe: "https://disk.example/0")

        // ... and one more result is detected
        service.storeResult(nil, for: try #require(URL(string: "https://example.com/\(UUID().uuidString).jpg")))

        // THEN the newest results are still cached
        #expect(service.cachedResult(for: fresh) != nil)
    }

    @Test func noRegionStoredBeforeDiskLoadWins() async throws {
        defer { try? FileManager.default.removeItem(at: diskURL) }

        // GIVEN an older result on disk
        let url = try #require(URL(string: "https://example.com/image.jpg"))
        let onDisk: [String: CGRect?] = [
            url.absoluteString: CGRect(x: 0, y: 0, width: 1, height: 1),
            "https://disk.example/probe": CGRect(x: 0, y: 0, width: 1, height: 1)
        ]
        try JSONEncoder().encode(onDisk).write(to: diskURL)

        // WHEN a newer "no region" result is stored before the disk load finishes
        let service = ImageSaliencyService(diskURL: diskURL)
        service.storeResult(nil, for: url)
        try await waitForDiskLoad(of: service, probe: "https://disk.example/probe")

        // THEN the newer result is kept
        #expect(service.cachedResult(for: url) == .noRegion)
    }

    private func waitForDiskLoad(of service: ImageSaliencyService, probe: String) async throws {
        let probeURL = try #require(URL(string: probe))
        let deadline = ContinuousClock.now + .seconds(5)
        while service.cachedResult(for: probeURL) == nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(service.cachedResult(for: probeURL) != nil)
    }
}

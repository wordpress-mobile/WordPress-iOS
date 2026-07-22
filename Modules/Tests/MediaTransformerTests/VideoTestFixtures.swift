import AVFoundation
import Foundation

// Shared video fixtures for the media upload tests. Used by both
// `UploadSourceMaterializerTests` (end-to-end, in `WordPressMediaLibraryTests`)
// and `MediaTransformerTests` (the transform engine in isolation).

/// Encoding a video is the most expensive fixture in these suites, and every
/// consumer only reads the source file, so all tests share a single clip.
let sharedBlankVideoTask = Task { try await createBlankVideo(durationSeconds: 1.0) }

/// Creates a 1-second blank H.264 video using AVAssetWriter, optionally
/// tagged with container-level metadata.
func createBlankVideo(
    durationSeconds: Double,
    metadata: [AVMetadataItem] = [],
    in directory: URL = FileManager.default.temporaryDirectory
) async throws -> URL {
    let url = directory.appendingPathComponent("blank_\(UUID().uuidString).mp4")

    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    writer.metadata = metadata
    let settings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: 320,
        AVVideoHeightKey: 240
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    writer.add(input)

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 320,
            kCVPixelBufferHeightKey as String: 240
        ]
    )

    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    // Write a single black frame at t=0.
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(
        kCFAllocatorDefault,
        320,
        240,
        kCVPixelFormatType_32BGRA,
        [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary,
        &pixelBuffer
    )
    if let pb = pixelBuffer {
        CVPixelBufferLockBaseAddress(pb, [])
        let ptr = CVPixelBufferGetBaseAddress(pb)
        memset(ptr, 0, CVPixelBufferGetDataSize(pb))
        CVPixelBufferUnlockBaseAddress(pb, [])
        adaptor.append(pb, withPresentationTime: .zero)
    }

    input.markAsFinished()

    return try await withCheckedThrowingContinuation { cont in
        writer.endSession(atSourceTime: CMTime(seconds: durationSeconds, preferredTimescale: 600))
        writer.finishWriting {
            if writer.status == .completed {
                cont.resume(returning: url)
            } else {
                cont.resume(throwing: writer.error ?? NSError(domain: "Test", code: 20))
            }
        }
    }
}

func videoHasLocation(_ url: URL) async throws -> Bool {
    let asset = AVURLAsset(url: url)
    for format in try await asset.load(.availableMetadataFormats) {
        for item in try await asset.loadMetadata(for: format) {
            let identifier = (item.identifier?.rawValue ?? "").lowercased()
            if identifier.contains("loci") || identifier.contains("location") { return true }
        }
    }
    return false
}

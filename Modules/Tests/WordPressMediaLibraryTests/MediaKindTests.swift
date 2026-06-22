import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPressMediaLibrary

struct MediaKindTests {
    @Test func payloadImageMapsToImage() {
        let details = ImageMediaDetails(fileSize: 0, width: 100, height: 100, file: "x.jpg", sizes: nil)
        #expect(MediaKind(payload: .image(details)) == .image)
    }

    @Test func payloadVideoMapsToVideo() {
        let details = VideoMediaDetails(
            fileSize: 0,
            length: 0,
            width: 0,
            height: 0,
            fileFormat: nil,
            dataFormat: nil,
            createdTimestamp: nil
        )
        #expect(MediaKind(payload: .video(details)) == .video)
    }

    @Test func payloadAudioMapsToAudio() {
        // AudioMediaDetails has 13 init parameters: fileSize, length (UInt64),
        // lengthFormatted, plus ten optional metadata fields. Pass minimal
        // valid values.
        let details = AudioMediaDetails(
            fileSize: 0,
            length: 0,
            lengthFormatted: "",
            dataFormat: nil,
            codec: nil,
            sampleRate: nil,
            channels: nil,
            bitsPerSample: nil,
            lossless: nil,
            channelMode: nil,
            bitrate: nil,
            compressionRatio: nil,
            fileFormat: nil
        )
        #expect(MediaKind(payload: .audio(details)) == .audio)
    }

    @Test func payloadDocumentMapsToDocument() {
        let details = DocumentMediaDetails(fileSize: 0)
        #expect(MediaKind(payload: .document(details)) == .document)
    }
}

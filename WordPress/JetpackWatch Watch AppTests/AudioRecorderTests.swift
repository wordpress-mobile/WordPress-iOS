import Testing
import Foundation
import AVFoundation
@testable import JetpackWatch_Watch_App

@Suite("AudioRecorder")
@MainActor
struct AudioRecorderTests {

    private func makeRecorder() -> (recorder: AudioRecorder, tempDir: URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioRecorderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return (AudioRecorder(rootURL: tempDir), tempDir)
    }

    @Test func fileURL_for_id_is_inside_root() {
        let (recorder, tempDir) = makeRecorder()
        let id = UUID()
        let url = recorder.fileURL(for: id)
        #expect(url.path.hasPrefix(tempDir.path))
        #expect(url.lastPathComponent == "\(id.uuidString).m4a")
    }

    @Test func cancel_removes_partial_file() throws {
        let (recorder, _) = makeRecorder()
        let id = UUID()
        let url = recorder.fileURL(for: id)

        try Data([0x00, 0x01]).write(to: url)
        #expect(FileManager.default.fileExists(atPath: url.path))

        recorder.cancel(id: id)
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }

    @Test func maximumDuration_is_300_seconds() {
        #expect(AudioRecorder.maximumDuration == 300)
    }

    @Test func recording_settings_are_aac_mono_32kbps_16khz() {
        let settings = AudioRecorder.recordSettings
        #expect(settings[AVFormatIDKey] as? UInt32 == kAudioFormatMPEG4AAC)
        #expect(settings[AVNumberOfChannelsKey] as? Int == 1)
        #expect(settings[AVSampleRateKey] as? Double == 16_000)
        #expect(settings[AVEncoderBitRateKey] as? Int == 32_000)
    }
}

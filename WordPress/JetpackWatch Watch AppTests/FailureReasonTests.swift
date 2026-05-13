import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("FailureReason")
struct FailureReasonTests {

    @Test(arguments: [
        ("upload_error",        FailureReason.uploadError),
        ("transcription_error", FailureReason.transcriptionError),
        ("draft_error",         FailureReason.draftError),
        ("site_forbidden",      FailureReason.siteForbidden),
        ("invalid_audio",       FailureReason.invalidAudio),
        ("timeout",             FailureReason.timeout),
        ("cancelled",           FailureReason.cancelled),
    ] as [(String, FailureReason)])
    func raw_value_parses_to_expected_case(rawValue: String, expected: FailureReason) {
        #expect(FailureReason(rawValue: rawValue) == expected)
    }

    @Test(arguments: FailureReason.allCases)
    func each_case_has_non_empty_user_facing_message(reason: FailureReason) {
        #expect(!reason.userFacingMessage.isEmpty)
    }

    @Test func unknown_raw_value_parses_to_nil() {
        #expect(FailureReason(rawValue: "unknown_reason") == nil)
    }
}

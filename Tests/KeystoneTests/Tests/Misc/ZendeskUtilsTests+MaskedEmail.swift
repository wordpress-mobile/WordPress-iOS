import Testing

@testable import WordPress

struct ZendeskUtilsMaskedEmailTests {

    @Test(
        arguments: [
            ("jeremy.massel@gmail.com", "j************@gmail.com"),
            ("first+tag@example.com", "f********@example.com"),
            ("a@example.com", "a@example.com"),
            ("quoted@name@example.com", "q**********@example.com"),
            ("no-at-sign", "n*********"),
            ("@example.com", "@example.com"),
            ("", "")
        ]
    )
    func masksTheLocalPart(email: String, expected: String) {
        #expect(ZendeskUtils.maskedEmail(email) == expected)
    }
}

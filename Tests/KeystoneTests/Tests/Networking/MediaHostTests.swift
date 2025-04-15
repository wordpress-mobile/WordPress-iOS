import Testing
@testable import WordPress

struct MediaHostTests {
    @Test func initializationWithPublicSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: false,
            isPrivate: false,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil,
            failure: { _ in Issue.record("Should not fail") }
        )

        #expect(host == .publicSite)
    }

    @Test func initializationWithPublicWPComSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: false,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil,
            failure: { _ in Issue.record("Should not fail") }
        )

        #expect(host == .publicWPComSite)
    }

    @Test func initializationWithPrivateSelfHostedSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: false,
            isPrivate: true,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil,
            failure: { _ in Issue.record("Should not fail") }
        )

        #expect(host == .privateSelfHostedSite)
    }

    @Test func initializationWithPrivateWPComSite() {
        let authToken = "letMeIn!"

        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: authToken,
            failure: { _ in Issue.record("Should not fail") }
        )

        #expect(host == .privateWPComSite(authToken: authToken))
    }

    @Test func initializationWithPrivateAtomicWPComSite() {
        let siteID = 16557
        let username = "demouser"
        let authToken = "letMeIn!"

        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: true,
            siteID: siteID,
            username: username,
            authToken: authToken,
            failure: { _ in Issue.record("Should not fail") }
        )

        #expect(host == .privateAtomicWPComSite(siteID: siteID, username: username, authToken: authToken))
    }

    @Test func initializationWithPrivateAtomicWPComSiteWithoutAuthTokenFails() async {
        await withUnsafeContinuation { continuation in
            let _ = MediaHost(
                isAccessibleThroughWPCom: true,
                isPrivate: true,
                isAtomic: true,
                siteID: 16557,
                username: "demouser",
                authToken: nil) { error in
                    #expect(error == .wpComPrivateSiteWithoutAuthToken)
                    continuation.resume()
                }
        }
    }

    @Test func initializationWithPrivateAtomicWPComSiteWithoutUsernameFails() async {
        await withUnsafeContinuation { continuation in
            let _ = MediaHost(
                isAccessibleThroughWPCom: true,
                isPrivate: true,
                isAtomic: true,
                siteID: 16557,
                username: nil,
                authToken: "letMeIn!") { error in
                    #expect(error == .wpComPrivateSiteWithoutUsername)
                    continuation.resume()
            }
        }
    }

    @Test func initializationWithPrivateAtomicWPComSiteWithoutSiteIDFails() async {
        await withUnsafeContinuation { continuation in
            let _ = MediaHost(
                isAccessibleThroughWPCom: true,
                isPrivate: true,
                isAtomic: true,
                siteID: nil,
                username: nil,
                authToken: nil) { error in
                    continuation.resume()
                }
        }
    }
}

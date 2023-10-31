import XCTest

@testable import WordPress

class MediaRepositoryTests: CoreDataTestCase {

    private var repository: MediaRepository!
    private var remote: MediaServiceRemoteStub!
    private var blogID: TaggedManagedObjectID<Blog>!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let accountService = AccountService(coreDataStack: contextManager)
        let accountID = accountService.createOrUpdateAccount(withUsername: "username", authToken: "token")
        try accountService.setDefaultWordPressComAccount(XCTUnwrap(mainContext.existingObject(with: accountID) as? WPAccount))

        let blog = try BlogBuilder(mainContext).withAccount(id: accountID).build()

        contextManager.saveContextAndWait(mainContext)

        blogID = TaggedManagedObjectID(blog)
        remote = MediaServiceRemoteStub()
        repository = MediaRepository(coreDataStack: contextManager, remoteFactory: MediaServiceRemoteFactoryStub(remote: remote))
    }

    func testGetMedia() async throws {
        let remoteMedia = RemoteMedia()
        remoteMedia.caption = "This is a test image"
        remote.getMediaResult = .success(remoteMedia)

        let mediaID = try await repository.getMedia(withID: 1, in: blogID)
        let caption = try await contextManager.performQuery { try $0.existingObject(with: mediaID).caption }
        XCTAssertEqual(caption, "This is a test image")
    }

    func testGetMediaError() async throws {
        let remoteMedia = RemoteMedia()
        remoteMedia.caption = "This is a test image"
        remote.getMediaResult = .failure(NSError.testInstance(code: 404))

        do {
            let _ = try await repository.getMedia(withID: 1, in: blogID)
            XCTFail("The getMedia call should throw")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}

private class MediaServiceRemoteFactoryStub: MediaServiceRemoteFactory {
    let remote: MediaServiceRemote

    init(remote: MediaServiceRemote) {
        self.remote = remote
    }

    override func remote(for blog: Blog) -> MediaServiceRemote? {
        remote
    }
}

private class MediaServiceRemoteStub: NSObject, MediaServiceRemote {
    var getMediaResult: Result<RemoteMedia, Error> = .failure(testError())

    func getMediaWithID(_ mediaID: NSNumber!, success: ((RemoteMedia?) -> Void)!, failure: ((Error?) -> Void)!) {
        switch getMediaResult {
        case let .success(media): success(media)
        case let .failure(error): failure(error)
        }
    }

    func uploadMedia(_ media: RemoteMedia!, progress: AutoreleasingUnsafeMutablePointer<Progress?>!, success: ((RemoteMedia?) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func update(_ media: RemoteMedia!, success: ((RemoteMedia?) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func delete(_ media: RemoteMedia!, success: (() -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func getMediaLibrary(pageLoad: (([Any]?) -> Void)!, success: (([Any]?) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func getMediaLibraryCount(forType mediaType: String!, withSuccess success: ((Int) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func getMetadataFromVideoPressID(_ videoPressID: String!, isSitePrivate: Bool, success: ((WordPressKit.RemoteVideoPressVideo?) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }

    func getVideoPressToken(_ videoPressID: String!, success: ((String?) -> Void)!, failure: ((Error?) -> Void)!) {
        fatalError("Unimplemented")
    }
}

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


    // MARK: - Deleting Media

    func testDeletingMediaSuccess_WhenItsSynced() async throws {
        remote.deleteMediaResult = .success(())

        // Prepare the test data
        let mediaID = try await contextManager.performAndSave { context in
            let media = MediaBuilder(context)
                .with(remoteStatus: .sync)
                .with(autoUploadFailureCount: Media.maxAutoUploadFailureCount)
                .build()
            media.blog = BlogBuilder(context).build()
            return TaggedManagedObjectID(media)
        }

        // Make sure the media exists
        var mediaExists = await contextManager.performQuery { context in
            (try? context.existingObject(with: mediaID)) != nil
        }
        XCTAssertTrue(mediaExists)

        // Call the method to delete the media object, remotely and locally.
        try await repository.delete(mediaID)

        // The media object should be deleted afterwards
        mediaExists = await contextManager.performQuery { context in
           (try? context.existingObject(with: mediaID)) != nil
        }
        XCTAssertFalse(mediaExists)
    }

    func testDeletingMediaFailure_WhenAPICallFails() async throws {
        remote.deleteMediaResult = .failure(NSError.testInstance(code: 404))

        // Prepare the test data
        let mediaID = try await contextManager.performAndSave { context in
            let media = MediaBuilder(context)
                .with(remoteStatus: .sync)
                .with(autoUploadFailureCount: Media.maxAutoUploadFailureCount)
                .build()
            media.blog = BlogBuilder(context).build()
            return TaggedManagedObjectID(media)
        }

        // Make sure the media exists
        var mediaExists = await contextManager.performQuery { context in
            (try? context.existingObject(with: mediaID)) != nil
        }
        XCTAssertTrue(mediaExists)

        let expectation = expectation(description: "The delete call should throw error")
        do {
            // Call the method to delete the media object, remotely and locally.
            try await repository.delete(mediaID)
        } catch let error as NSError {
            expectation.fulfill()
            XCTAssertEqual(error.code, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        await fulfillment(of: [expectation])

        // The local Media object should not be deleted because the API call failed.
        mediaExists = await contextManager.performQuery { context in
           (try? context.existingObject(with: mediaID)) != nil
        }
        XCTAssertTrue(mediaExists)
    }

}

private class MediaServiceRemoteFactoryStub: MediaServiceRemoteFactory {
    let remote: MediaServiceRemote

    init(remote: MediaServiceRemote) {
        self.remote = remote
    }

    override func remote(for blog: Blog) throws -> MediaServiceRemote {
        remote
    }
}

private class MediaServiceRemoteStub: NSObject, MediaServiceRemote {
    var getMediaResult: Result<RemoteMedia, Error> = .failure(testError())
    var deleteMediaResult: Result<Void, Error> = .failure(testError())

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
        switch deleteMediaResult {
        case .success: success()
        case let .failure(error): failure(error)
        }
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

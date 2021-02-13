//
//  StoryPosterTests.swift
//  WordPressTest
//
//  Created by Brandon Titus on 11/12/20.
//  Copyright © 2020 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

class StoryPosterTests: XCTestCase {

    var poster: StoryPoster!

    override func setUpWithError() throws {
        poster = StoryPoster(context: MockContext.getContext()!)
    }

    func testPostContent() throws {

        let files = [
            StoryPoster.MediaFile(alt: "",
                     caption: "",
                     id: 0,
                     link: "",
                     mime: "",
                     type: "",
                     url: "http://google.com")
        ]

        let json = poster.json(files: files)
        let content = poster.wrap(json: json)
        let unwrappedJSON = try poster.parse(string: content)
        let decoded = try poster.decode(data: unwrappedJSON.data(using: .utf8)!)
        XCTAssertEqual(files, decoded, "Input files should equal decoded files")
    }
}

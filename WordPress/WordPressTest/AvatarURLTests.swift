//
//  AvatarURLTests.swift
//  WordPress
//
//  Created by Andrew McKnight on 11/28/16.
//

import XCTest
@testable import WordPress

class BlavatarURLTests: XCTestCase {
    func testBlavatarURL() {
        let size = 80
        let urlString = "https://secure.gravatar.com/blavatar/a5a6f6271612597ddc27e356a404f967"
        let expected = NSURL(string: "https://secure.gravatar.com/blavatar/a5a6f6271612597ddc27e356a404f967?d=404&s=\(size)")
        let actual = WPImageURLHelper.blavatarURL(forBlavatarURL: urlString, size: size)
        XCTAssert(expected == actual, "expected \(expected) but got \(actual)")
    }

    func testBlavatarURLForHost() {
        let size = 80
        let host = "somewhere.wordpress.com"
        let expected = NSURL(string: "http:/gravatar.com/avatar/c10a709bbd4724d58eb530312be0b033?d=404&s=\(size)")
        let actual = WPImageURLHelper.blavatarURL(forHost: host, size: size)
        XCTAssert(expected == actual, "expected \(expected) but got \(actual)")
    }

    func testGravatarURLWithEmail() {
        let email = "someone_anyone@wordpresss.com"
        let size = 80
        let rating = WPImageURLHelper.ImageRatingValue.G.rawValue
        let actual = WPImageURLHelper.gravatarURL(forEmail: email, size: size, rating: rating)
        let expected = NSURL(string: "http:/gravatar.com/avatar/93309dffc5d0b98d52fe463931e2ad27?d=404&s=\(size)&r=g")
        XCTAssert(expected == actual, "expected \(expected) but got \(actual)")
    }
}

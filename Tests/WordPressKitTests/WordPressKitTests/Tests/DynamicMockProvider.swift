import UIKit

protocol DynamicMockProvider {
    static func randomString(length: Int) -> String
    static func randomInt(limit: Int) -> Int
    static func randomURLAsString(length: Int) -> String
    static func randomIntAsString(limit: Int) -> String
}

internal extension DynamicMockProvider {
    static func randomString(length: Int = 50) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }

    static func randomInt(limit: Int = 1000) -> Int {
        return Int.random(in: 0..<limit)
    }

    static func randomURLAsString(length: Int = 50) -> String {
        let host = "https://"
        let tlds = [".com", ".org", ".blog", ".co.nz", ".co.uk", ".edu", ".gov"]

        return host + randomString(length: length) + tlds[Int.random(in: 0 ..< (tlds.count-1))]
    }

    static func randomURLAsString(withLength length: Int, subDirectories: [String]?, file: String?) -> String {
        var urlString = randomURLAsString(length: length)

        if let subDirectories = subDirectories {
            for directory in subDirectories {
                urlString += "/\(directory)"
            }
        }

        if let file = file {
            urlString += "/\(file)"
        }

        return urlString
    }

    static func randomIntAsString(limit: Int = 10000) -> String {
        return String(randomInt(limit: limit))
    }

    static func randomBool() -> Bool {
        return Bool.random()
    }
}

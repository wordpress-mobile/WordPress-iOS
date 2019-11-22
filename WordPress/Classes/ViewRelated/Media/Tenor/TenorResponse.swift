//
//  TenorResponse.swift
//  WordPress
//
//  Created by Cihan Tek on 21.11.2019.
//  Copyright © 2019 WordPress. All rights reserved.
//

import Foundation

typealias TenorGifFormat = TenorMedia.MediaCodingKeys

class TenorResponse: Decodable {
    let next: String
    let results: [TenorMedia]
}

class TenorMedia: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case created
        case itemurl
        case title
        case media
    }
    
    enum MediaCodingKeys: String, CodingKey, CaseIterable {
        case nanogif
        case tinygif
        case mediumgif
        case gif
    }
    
    let id: String
    let created: Date
    let itemurl: String
    let title: String
    
    var gifs: [TenorGifFormat: TenorGif] // Data format in the response has unnecessary depth. We'll convert it to a more optimal format
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: CodingKeys.id)
        
        let createdDate = try container.decode(Float.self, forKey: CodingKeys.created)
        created = Date(timeIntervalSince1970: Double(createdDate))
        
        itemurl = try container.decode(String.self, forKey: CodingKeys.itemurl)
        title = try container.decode(String.self, forKey: CodingKeys.title)
        
        var mediaContainer = try container.nestedUnkeyedContainer(forKey: CodingKeys.media)
        
        gifs = [TenorGifFormat: TenorGif]()
        
        while !mediaContainer.isAtEnd {
            let gifsContainer = try mediaContainer.nestedContainer(keyedBy: MediaCodingKeys.self)
            for key in MediaCodingKeys.allCases {
                gifs[key] = try gifsContainer.decode(TenorGif.self, forKey: key)
            }
        }
    }
}

class TenorGif: Codable {
    let url: String
    let dims: [Int]
    let preview: String
}

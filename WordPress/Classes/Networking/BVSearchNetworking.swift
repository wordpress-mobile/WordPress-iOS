//
//  BVSearchNetworking.swift
//  BeauVoyage
//
//  Created by Lukasz Koszentka on 8/21/20.
//  Copyright © 2020 BeauVoyage. All rights reserved.
//

import Foundation

protocol BVSearchNetworking {
    func performSearch(with query: String,
                       page: Int,
                       success: @escaping ReaderSiteSearchSuccessBlock,
                       failure: @escaping ReaderSiteSearchFailureBlock)
}

final class BVSearchNetworkingImpl: BVSearchNetworking {

    func performSearch(with query: String,
                       page: Int,
                       success: @escaping ReaderSiteSearchSuccessBlock,
                       failure: @escaping ReaderSiteSearchFailureBlock) {
//
//        let endpoint = "read/feed"
//        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
//        let parameters: [String: AnyObject] = [
//            "number": count as AnyObject,
//            "offset": offset as AnyObject,
//            "exclude_followed": false as AnyObject,
//            "sort": "relevance" as AnyObject,
//            "meta": "site" as AnyObject,
//            "q": query as AnyObject
//        ]

    }

}

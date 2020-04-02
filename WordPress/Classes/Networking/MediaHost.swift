//
//  MediaHost.swift
//  WordPress
//
//  Created by Diego E. Rey Mendez on 2/4/20.
//  Copyright © 2020 WordPress. All rights reserved.
//

import Foundation

/// Defines a media host for request authentication purposes.
///
enum MediaHost {
    case publicSite
    case privateSelfHostedSite
    case privateWPComSite
    case privateAtomicWPComSite(siteID: Int)

    enum Error: Swift.Error {
        case wpComWithoutSiteID
    }

    init(
        isAccessibleThroughWPCom: Bool,
        isPrivate: Bool,
        isAtomic: Bool,
        siteID: Int?,
        failure: (Error) -> ()) {

        guard isPrivate else {
            self = .publicSite
            return
        }

        guard isAccessibleThroughWPCom else {
            self = .privateSelfHostedSite
            return
        }

        guard isAtomic else {
            self = .privateWPComSite
            return
        }

        guard let siteID = siteID else {
            // This should actually not be possible.  We have no good way to
            // handle this.
            failure(Error.wpComWithoutSiteID)

            // If the caller wants to kill execution, they can do it in the failure block
            // call above.
            //
            // Otherwise they'll be able to continue trying to request the image as if it
            // was hosted in a private WPCom site.  This is the best we can offer with the
            // provided input parameters.
            self = .privateWPComSite
            return
        }

        self = .privateAtomicWPComSite(siteID: siteID)
    }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `AbstractPost`.
///
extension MediaHost {
    init(with post: AbstractPost, failure: (BlogError) -> ()) {
        self.init(with: post.blog, failure: failure)
   }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum BlogError: Swift.Error {
        case wpComWithoutSiteID(blog: Blog)
    }

    init(with blog: Blog, failure: (BlogError) -> ()) {
        self.init(isAccessibleThroughWPCom: blog.isAccessibleThroughWPCom(),
            isPrivate: blog.isPrivate(),
            isAtomic: blog.isAtomic(),
            siteID: blog.dotComID?.intValue,
            failure: { error in
            switch error {
                case .wpComWithoutSiteID:
                    // We can add valuable information by replacing this error case.
                    failure(BlogError.wpComWithoutSiteID(blog: blog))
                }
        })
   }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum ReaderPostContentProviderError: Swift.Error {
        case wpComWithoutSiteID(readerPostContentProvider: ReaderPostContentProvider)
    }

    init(with readerPostContentProvider: ReaderPostContentProvider, failure: (ReaderPostContentProviderError) -> ()) {
        let isAccessibleThroughWPCom = readerPostContentProvider.isWPCom() || readerPostContentProvider.isJetpack()

        self.init(isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: readerPostContentProvider.isPrivate(),
            isAtomic: readerPostContentProvider.isAtomic(),
            siteID: readerPostContentProvider.siteID()?.intValue,
            failure: { error in
                switch error {
                case .wpComWithoutSiteID:
                    // We can add valuable information by replacing this error case.
                    failure(ReaderPostContentProviderError.wpComWithoutSiteID(readerPostContentProvider: readerPostContentProvider))
                }
        })
    }
}

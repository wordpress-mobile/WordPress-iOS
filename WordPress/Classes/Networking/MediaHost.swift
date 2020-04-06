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
enum MediaHost: Equatable {
    case publicSite
    case publicWPComSite
    case privateSelfHostedSite
    case privateWPComSite(authToken: String)
    case privateAtomicWPComSite(siteID: Int, username: String, authToken: String)

    enum Error: Swift.Error {
        case wpComWithoutSiteID
        case wpComPrivateSiteWithoutAuthToken
        case wpComPrivateSiteWithoutUsername
    }

    init(
        isAccessibleThroughWPCom: Bool,
        isPrivate: Bool,
        isAtomic: Bool,
        siteID: Int? = nil,
        username: String? = nil,
        authToken: String? = nil,
        failure: (Error) -> ()) {

        guard isPrivate else {
            if isAccessibleThroughWPCom {
                self = .publicWPComSite
            } else {
                self = .publicSite
            }
            return
        }

        guard isAccessibleThroughWPCom else {
            self = .privateSelfHostedSite
            return
        }

        guard let authToken = authToken else {
            // This should actually not be possible.  We have no good way to
            // handle this.
            failure(Error.wpComPrivateSiteWithoutAuthToken)

            // If the caller wants to kill execution, they can do it in the failure block
            // call above.
            //
            // Otherwise they'll be able to continue trying to request the image as if it
            // was hosted in a public WPCom site.  This is the best we can offer with the
            // provided input parameters.
            self = .publicSite
            return
        }

        guard isAtomic else {
            self = .privateWPComSite(authToken: authToken)
            return
        }

        guard let username = username else {
            // This should actually not be possible.  We have no good way to
            // handle this.
            failure(Error.wpComPrivateSiteWithoutUsername)

            // If the caller wants to kill execution, they can do it in the failure block
            // call above.
            //
            // Otherwise they'll be able to continue trying to request the image as if it
            // was hosted in a private WPCom site.  This is the best we can offer with the
            // provided input parameters.
            self = .privateWPComSite(authToken: authToken)
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
            self = .privateWPComSite(authToken: authToken)
            return
        }

        self = .privateAtomicWPComSite(siteID: siteID, username: username, authToken: authToken)
    }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `AbstractPost`.
///
extension MediaHost {
    enum PostError: Swift.Error {
        case baseInitializerError(error: BlogError, post: AbstractPost)
    }

    init(with post: AbstractPost, failure: (PostError) -> ()) {
        self.init(
            with: post.blog,
            failure: { error in
                // We just associate a blog with the underlying error for simpler debugging.
                failure(PostError.baseInitializerError(
                    error: error,
                    post: post))
        })
   }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum BlogError: Swift.Error {
        case baseInitializerError(error: Error, blog: Blog)
    }

    init(with blog: Blog, failure: (BlogError) -> ()) {
        self.init(isAccessibleThroughWPCom: blog.isAccessibleThroughWPCom(),
            isPrivate: blog.isPrivate(),
            isAtomic: blog.isAtomic(),
            siteID: blog.dotComID?.intValue,
            failure: { error in
                // We just associate a blog with the underlying error for simpler debugging.
                failure(BlogError.baseInitializerError(
                    error: error,
                    blog: blog))
        })
   }
}

/// Extends `MediaRequestAuthenticator.ImageHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum ReaderPostContentProviderError: Swift.Error {
        case baseInitializerError(error: Error, readerPostContentProvider: ReaderPostContentProvider)
    }

    init(with readerPostContentProvider: ReaderPostContentProvider, failure: (ReaderPostContentProviderError) -> ()) {
        let isAccessibleThroughWPCom = readerPostContentProvider.isWPCom() || readerPostContentProvider.isJetpack()

        self.init(isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: readerPostContentProvider.isPrivate(),
            isAtomic: readerPostContentProvider.isAtomic(),
            siteID: readerPostContentProvider.siteID()?.intValue,
            failure: { error in
                // We just associate a blog with the underlying error for simpler debugging.
                failure(ReaderPostContentProviderError.baseInitializerError(
                    error: error,
                    readerPostContentProvider: readerPostContentProvider))
        })
    }
}

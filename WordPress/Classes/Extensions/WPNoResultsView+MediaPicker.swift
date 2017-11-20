//
//  MediaNoResultView.swift
//  WordPress
//
//  Created by Eduardo Toledo on 11/18/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation

extension WPNoResultsView {

    func updateForNoSearchResult(searchQuery: String) {
        accessoryView = UIImageView(image: UIImage(named: "media-no-results"))
        let text = NSLocalizedString("No media files match your search for %@", comment: "Message displayed when no results are returned from a media library search. Should match Calypso.")
        titleText = String.localizedStringWithFormat(text, searchQuery)
        messageText = nil
        buttonTitle = nil
        sizeToFit()
    }

    func updateForNoMediaAssets(userCanUploadMedia: Bool) {
        accessoryView = UIImageView(image: UIImage(named: "media-no-results"))
        titleText = NSLocalizedString("You don't have any media.", comment: "Title displayed when the user doesn't have any media in their media library. Should match Calypso.")

        if userCanUploadMedia {
            messageText = NSLocalizedString("Would you like to upload something?", comment: "Prompt displayed when the user has an empty media library. Should match Calypso.")
            buttonTitle = NSLocalizedString("Upload Media", comment: "Title for button displayed when the user has an empty media library")
        }
        sizeToFit()
    }

    func updateForMediaFetching() {
        titleText = NSLocalizedString("Fetching media...", comment: "Title displayed whilst fetching media from the user's media library")
        messageText = nil
        buttonTitle = nil

        let animatedBox = WPAnimatedBox()
        accessoryView = animatedBox

        animatedBox.animate(afterDelay: 0.1)
        sizeToFit()
    }
}

//
//  ShareViewController.swift
//  WordPressShare
//
//  Created by Aaron Douglas on 2/23/16.
//  Copyright © 2016 WordPress. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }

    override func configurationItems() -> [AnyObject]! {
        let blogPickerItem = SLComposeSheetConfigurationItem()
        blogPickerItem.title = NSLocalizedString("Post to:", comment: "Upload post to the selected Site")
        blogPickerItem.value = "Primary Site"
        blogPickerItem.tapHandler = { [weak self] in
            self?.displayBlogPicker()
        }
        
        return [blogPickerItem]
    }

    
    private func displayBlogPicker() {
        let pickerViewController = BlogPickerViewController()
        pushConfigurationViewController(pickerViewController)
    }
}

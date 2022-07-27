import Foundation

class JetpackWindowManager: WindowManager {
    override func showUI(for blog: Blog?) {
        // If the user is logged in and has blogs sync'd to their account
        if AccountHelper.isLoggedIn && AccountHelper.hasBlogs {
            showAppUI(for: blog)
            return
        }

        // Show the sign in UI if the user isn't logged in
        guard AccountHelper.isLoggedIn else {
            showSignInUI()
            return
        }

        // If the user doesn't have any blogs, but they're still logged in, log them out
        // the `logOutDefaultWordPressComAccount` method will trigger the `showSignInUI` automatically
        AccountHelper.logOutDefaultWordPressComAccount()
    }
}

### v2.2.0
* [#30](https://github.com/chiunam/CTAssetsPickerController/issues/30) Refactor into separate files

### v2.1.0
* [#28](https://github.com/chiunam/CTAssetsPickerController/issues/28) Disable "Done" Button if no assets are selected
* Change "Done" Button style to `UIBarButtonItemStyleDone`


### v2.0.0
* Rename the delegate methods to more sensible one
* Replace certain properties with delegate methods in order to provide more flexibility
* Selected assets are preserved across albums
* Move title of selected assets to toolbar
* Show "no assets" view on empty albums
* Make "no assets" message to be more graceful, reflecting the device's model and camera feature
* Update padlock image to iOS 7 style
* Monitor ALAssetsLibraryChangedNotification and reload corresponding view controllers
* Use KVO to monitor the change of selected assets
* Add: Empty assets placeholder image
* Add: Selected assets property
* Add: Selected assets changed notification
* Add: Selection methods
* Add: iPad demo
* Add: Appledoc documentation
* Fix: Footer is not centre aligned after rotation
* Fix: Collection view layout issue on iPad landscape mode
* Fix: Collection view not scrolling to bottom on load
* Refactor certain methods

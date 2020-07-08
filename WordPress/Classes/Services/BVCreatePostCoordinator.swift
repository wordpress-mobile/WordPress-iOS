//import UIKit
//
//protocol BVCreatePostCoordinator {
//    func start(navigtionController: UINavigationController)
//}
//
//final class BVCreatePostCoordinatorImpl: NSObject, BVCreatePostCoordinator {
//
//    var imageData: Data?
//    var featuredImage: UIImage?
//    var mediaDataSource: WPAndDeviceMediaLibraryDataSource?
//
//    func start(navigtionController: UINavigationController) {
//        if let image = featuredImage {
//
//        } else {
//
//        }
////            if (self.featuredImage) {
////                FeaturedImageViewController *featuredImageVC;
////                if (self.animatedFeaturedImageData) {
////                    featuredImageVC = [[FeaturedImageViewController alloc] initWithGifData:self.animatedFeaturedImageData];
////                } else {
////                    featuredImageVC = [[FeaturedImageViewController alloc] initWithImage:self.featuredImage];
////                }
////
////                featuredImageVC.delegate = self;
////
////                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:featuredImageVC];
////                [self presentViewController:navigationController animated:YES completion:nil];
////            } else if ([self urlForFeaturedImage] == nil) {
////                //If we don't have a featured image url, the image won't be loaded.
////                [self showMediaPicker];
////            }
////        } else {
////            if (!self.isUploadingMedia) {
////                [self showMediaPicker];
////            }
////        }
//    }
//
//    private func showMediaPicker(navigtionController: UINavigationController) {
//        let options = WPMediaPickerOptions()
//        options.showMostRecentFirst = true
//        options.allowMultipleSelection = true
//        options.filter = .image
//        options.showSearchBar = true
////        options.badgedUTTypes = Set(kUTTypeGIF)
//        options.preferredStatusBarStyle = .lightContent
//        let picker = WPNavigationMediaPickerViewController()
//        let context = ContextManager.sharedInstance().mainContext
//        let postService = PostService(managedObjectContext: context)
//        let blogService = BlogService(managedObjectContext: context)
//        guard let blog = blogService.lastUsedOrFirstBlog() else { return }
//        let newPost = postService.createDraftPost(for: blog)
//        let mediaDataSource = WPAndDeviceMediaLibraryDataSource(post: newPost, initialDataSourceType: .mediaLibrary)
//        picker.dataSource = mediaDataSource
//        picker.delegate = self
////        [self registerChangeObserverForPicker:picker.mediaPicker];
//        picker.modalPresentationStyle = .formSheet
//        navigtionController.present(picker, animated: true)
////        [self presentViewController:picker animated:YES completion:nil];
////
//        self.mediaDataSource = mediaDataSource
//    }
//
//}
//
//extension BVCreatePostCoordinatorImpl: WPMediaPickerViewControllerDelegate {
//
//    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
//        if assets.isEmpty { return }
//
//        mediaDataSource?.searchCancelled()
//
//        if let asset = assets.first as? PHAsset {
//
//        } else if let asset = assets.first as? Media {
//
//        }
//
//        if ([[assets firstObject] isKindOfClass:[PHAsset class]]){
//            PHAsset *asset = [assets firstObject];
//            self.isUploadingMedia = YES;
//            [self setFeaturedImageWithAsset:asset];
//        } else if ([[assets firstObject] isKindOfClass:[Media class]]){
//            Media *media = [assets firstObject];
//            [self setFeaturedImageWithMedia:media];
//        }
//
//        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//
//        // Reload the featured image row so that way the activity indicator will be displayed.
//        NSIndexPath *featureImageCellPath = [NSIndexPath indexPathForRow:0 inSection:[self.sections indexOfObject:@(PostSettingsSectionFeaturedImage)]];
//        [self.tableView reloadRowsAtIndexPaths:@[featureImageCellPath]
//                              withRowAnimation:UITableViewRowAnimationFade];
//    }
//
//}

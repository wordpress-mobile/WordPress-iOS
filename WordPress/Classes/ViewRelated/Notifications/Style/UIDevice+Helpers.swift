import Foundation


extension UIDevice
{
    public class func isPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
}
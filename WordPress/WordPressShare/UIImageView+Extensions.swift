import Foundation


extension UIImageView
{    
    public func downloadImage(url: NSURL?, placeholderImage: UIImage?) {
        // Failsafe: Halt if the URL is empty
        guard let unwrappedUrl = url else {
            image = placeholderImage
            return
        }
        
        let request = NSMutableURLRequest(URL: unwrappedUrl)
        request.HTTPShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { [weak self] (data, response, error) -> Void in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            self?.image = image
        }
        
        task.resume()
    }

}

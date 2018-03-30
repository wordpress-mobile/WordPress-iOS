
import Foundation


class StockPhotosMediaExporter: MediaExporter {

    var mediaDirectoryType: MediaDirectory = .uploads

    let media: StockPhotosMedia

    init(stockPhotosMedia: StockPhotosMedia) {
        media = stockPhotosMedia
    }

    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        // Pass the export off to the image exporter

        downloadImage { (image) in
            let localURL = self.getLocalURL(for: image)
            let exporter = MediaImageExporter(url: localURL)
            exporter.mediaDirectoryType = self.mediaDirectoryType
            exporter.export(onCompletion: onCompletion, onError: onError)
        }

        return Progress.discreteCompletedProgress()
    }

    func downloadImage(completion: @escaping (UIImage) -> Void) {
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: self.media.thumbnails.largeURL)
                if let image = UIImage(data: data) {
                    completion(image)
                }
            } catch {

            }
        }
    }

    func getLocalURL(for image: UIImage) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("\(media.name).jpg")
        do {
            if let pngImageData = UIImagePNGRepresentation(image) {
                try pngImageData.write(to: fileURL, options: .atomic)
            }
        } catch {
            print(error)
        }
        return fileURL
    }
}


import AVFoundation
import UIKit


enum ReplayThumbnails {


    private static let maxPixelWidth: CGFloat = 480

    private static let cache = NSCache<NSString, UIImage>()

    private static func fileURL(for id: String) -> URL {
        ReplayStore.directory.appending(path: "\(id).jpg")
    }

    static func cached(id: String) -> UIImage? {
        if let image = cache.object(forKey: id as NSString) { return image }
        guard let data = try? Data(contentsOf: fileURL(for: id)),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: id as NSString)
        return image
    }


    static func image(for reel: ReplayReel) async -> UIImage? {
        if let image = cached(id: reel.id) { return image }

        let url = reel.videoURL
        let id = reel.id
        guard let image = await Task.detached(priority: .utility, operation: {
            await generate(url: url)
        }).value else { return nil }

        cache.setObject(image, forKey: id as NSString)
        if let data = image.jpegData(compressionQuality: 0.7) {
            try? data.write(to: fileURL(for: id), options: .atomic)
        }
        return image
    }

    static func remove(id: String) {
        cache.removeObject(forKey: id as NSString)
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    private static func generate(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelWidth, height: maxPixelWidth)


        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)

        guard let duration = try? await asset.load(.duration), duration.seconds > 0 else {
            return nil
        }
        let middle = CMTime(seconds: duration.seconds / 2, preferredTimescale: 600)
        guard let cgImage = try? await generator.image(at: middle).image else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

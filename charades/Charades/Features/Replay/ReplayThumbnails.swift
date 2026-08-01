import AVFoundation
import UIKit

/// Arşiv kartının görseli — §04 §4.3: "videonun ortasından alınan kare".
///
/// Kare her açılışta yeniden üretilmiyor, diske yazılıyor: 20 kayıtlık bir
/// arşivde 20 `AVAssetImageGenerator` kurulumu listeyi gözle görülür geciktiriyor
/// ve kart yerine boşluk gösteriyor. Küçük resim türetilmiş veri, kaydın kendisi
/// değil; silinirse yeniden üretiliyor.
enum ReplayThumbnails {

    /// Kart 132pt genişlikte, 3x ekranda 396px. 480 bu ölçünün üstünde kalıyor.
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

    /// Diskte varsa onu, yoksa videodan üretip yazdıktan sonra döndürüyor.
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
        // Kesin kare aramak kısa kayıtlarda saniyeler sürebiliyor; yarım saniyelik
        // tolerans kartın içeriğini değiştirmiyor.
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

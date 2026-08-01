import AVFoundation
import Foundation
import UIKit

/// Bir turun kaydı — 04-oyun-modlari.md §4.2–4.3.
///
/// Arşivin sözlüğü film: her **maç** bir film, her **tur** bir sahne. Tekil
/// turlarda da aynı yapı kullanılıyor, o zaman film tek sahnelik oluyor.
struct ReplayReel: Codable, Identifiable, Equatable {

    /// §04 §4.4 zaman çizelgesi işareti ve altyazısı. §09 §9: zaman referansı
    /// **video saati**, oyun saati değil — duraklatmada kayıt da durduğu için
    /// ikisi ayrışıyor.
    struct Mark: Codable, Equatable {
        let time: TimeInterval
        /// §09 §9: tur sonu düzeltmesi damgayı da çeviriyor; yoksa kullanıcı
        /// "doğru" diye düzelttiği kelimeyi replay'de kırmızı görüyor.
        var isCorrect: Bool
        /// Kelimenin o turda **ekranda göründüğü** hâli. Sonradan dil
        /// değiştirilse bile altyazı videodaki anı anlatmaya devam ediyor.
        let word: String
        /// Dilden bağımsız kart anahtarı; düzeltmeyi eşleştirmek için.
        let key: String
    }

    let id: String
    let createdAt: Date
    /// Aynı maçın sahnelerini arşivde gruplayan kimlik (§04 §4.3).
    let matchID: String
    let sceneIndex: Int
    var duration: TimeInterval
    /// Başlık çalışma anında çözülüyor: kayıt Türkçe alınıp arşive İngilizce
    /// bakılabiliyor, deste adının o an seçili dilde çıkması gerekiyor.
    let deckIDs: [String]
    let modeID: String
    let playerName: String?
    var marks: [Mark]
    /// §09 §2: gelen çağrı ya da arka plan kaydı yarıda kesti, tur devam etti.
    var isPartial: Bool
    /// §04 §4.2: sabitlenen kayıt FIFO ve otomatik temizlikten muaf (P15).
    var isPinned: Bool

    var correctCount: Int { marks.filter(\.isCorrect).count }

    var videoURL: URL { ReplayStore.videoURL(for: id) }
}

/// Kayıt dosyalarının yaşam döngüsü — §04 §4.2.
///
/// Konum kalıcı: ilk taslaktaki `tmp` kararı değişti, çünkü kamera izni
/// metninde "sonradan izleyebilmeniz için" derken kaydı uygulama kapanınca
/// silmek hem verilen sözü tutmuyor hem App Review'da izin metniyle gerçek
/// kullanımın uyuşmaması olarak işaretleniyor.
///
/// Kotanın olmaması bu tür özelliklerin klasik batış sebebi: birkaç hafta sonra
/// uygulama 4 GB yer kaplıyor, kullanıcı iOS Ayarlar → Depolama'da görüyor ve
/// uygulamayı siliyor. 20 kayıt / 500 MB sınırı bunu baştan engelliyor.
enum ReplayStore {

    /// §04 §4.2: hangisi önce dolarsa.
    static let maxReelCount = 20
    static let maxTotalBytes: Int64 = 500 * 1_000_000

    /// §06 §1: arşiv ekranındaki `Otomatik silme` segmenti.
    enum Retention: String, CaseIterable {
        case week
        case month
        case forever

        var days: Int? {
            switch self {
            case .week: 7
            case .month: 30
            case .forever: nil
            }
        }

        var labelKey: String { "archive.retention.\(rawValue)" }
    }

    static var directory: URL {
        URL.applicationSupportDirectory.appending(path: "Replays", directoryHint: .isDirectory)
    }

    static func videoURL(for id: String) -> URL {
        directory.appending(path: "\(id).mov")
    }

    private static func metadataURL(for id: String) -> URL {
        directory.appending(path: "\(id).json")
    }

    /// Klasörü oluşturup iCloud yedeğinden çıkarıyor. §04 §4.2: video yedeği
    /// kullanıcının iCloud kotasını yiyor ve şikâyet konusu oluyor.
    @discardableResult
    static func prepareDirectory() -> URL? {
        var url = directory
        let manager = FileManager.default

        if !manager.fileExists(atPath: url.path(percentEncoded: false)) {
            do {
                try manager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        return url
    }

    static func save(_ reel: ReplayReel) {
        guard prepareDirectory() != nil else { return }
        guard let data = try? JSONEncoder().encode(reel) else { return }
        try? data.write(to: metadataURL(for: reel.id), options: .atomic)
    }

    static func reel(id: String) -> ReplayReel? {
        guard let data = try? Data(contentsOf: metadataURL(for: id)) else { return nil }
        return try? JSONDecoder().decode(ReplayReel.self, from: data)
    }

    /// Video ve metadata birlikte gidiyor: yarısı kalan bir kayıt arşivde
    /// açılamayan bir kart demek.
    static func delete(id: String) {
        let manager = FileManager.default
        try? manager.removeItem(at: videoURL(for: id))
        try? manager.removeItem(at: metadataURL(for: id))
        ReplayThumbnails.remove(id: id)
    }

    static func allReels() -> [ReplayReel] {
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { reel(id: $0.deletingPathExtension().lastPathComponent) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Header'daki koşullu makara ikonu her ana ekran dönüşünde bunu soruyor;
    /// künyeleri çözmeye gerek yok, dosya saymak yetiyor.
    static func reelCount() -> Int {
        let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        return files?.count { $0.pathExtension == "json" } ?? 0
    }

    static func bytes(of reel: ReplayReel) -> Int64 {
        let values = try? videoURL(for: reel.id).resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    static func totalBytes() -> Int64 {
        allReels().reduce(0) { $0 + bytes(of: $1) }
    }

    static func deleteAll() {
        for reel in allReels() { delete(id: reel.id) }
    }

    // MARK: Kota ve temizlik

    /// Açılışta tek seferde: gizlilik sözü, öksüz dosyalar, yaş ve kota.
    static func runLaunchMaintenance(settings: AppSettingsStore) {
        if settings.replayWipeOnLaunch {
            deleteAll()
            return
        }
        removeOrphans()
        enforcePolicy(retention: settings.replayRetention)
    }

    /// Açılışta ve her yeni kayıttan sonra. Sıra §04 §4.2'deki gibi: önce yaşı
    /// geçenler, sonra kota. Sabitlenen kayıt ikisinden de muaf — kullanıcı
    /// "bunu saklıyorum" dediyse otomatik hiçbir kural onu silmiyor.
    static func enforcePolicy(retention: Retention) {
        var reels = allReels()

        if let days = retention.days {
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
            for reel in reels where !reel.isPinned && reel.createdAt < cutoff {
                delete(id: reel.id)
            }
            reels.removeAll { !$0.isPinned && $0.createdAt < cutoff }
        }

        // FIFO: en eski **sabitlenmemiş** kayıt gidiyor. `allReels` yeniden
        // eskiye sıralı, o yüzden kuyruktan başlanıyor.
        var sizes = Dictionary(uniqueKeysWithValues: reels.map { ($0.id, bytes(of: $0)) })
        var total = sizes.values.reduce(0, +)
        var evicted = 0

        while reels.count > maxReelCount || total > maxTotalBytes {
            guard let index = reels.lastIndex(where: { !$0.isPinned }) else { break }
            let victim = reels.remove(at: index)
            total -= sizes.removeValue(forKey: victim.id) ?? 0
            delete(id: victim.id)
            evicted += 1
        }

        // §03 §5: kullanıcının silmediği ama kaybettiği kayıtlar. Sık
        // görülüyorsa kota dar demektir; yaş temizliği bu sayıya girmiyor,
        // orası kullanıcının kendi seçtiği politika.
        if evicted > 0 { Analytics.replayQuotaEvict(count: evicted) }
    }

    #if DEBUG
    /// Simülatörde arşivi dolu görebilmek için. Kaynak makara yoksa sentetik
    /// bir video üretiliyor — aksi hâlde arşiv boşken tohumlama sessizce
    /// hiçbir şey yapmıyordu.
    static func debugSeed(copies: Int) {
        prepareDirectory()
        let source = allReels().first
        let sourceURL = source?.videoURL ?? makeSeedVideo()
        guard let sourceURL, FileManager.default.fileExists(atPath: sourceURL.path) else { return }

        let names = ["Ayşe", "Mehmet", "Zeynep", "Can", "Elif", "Deniz"]
        let decks = ["party", "movieClassics", "cities"]
        let marks = source?.marks ?? [
            .init(time: 3, isCorrect: true, word: "Zürafa", key: "giraffe"),
            .init(time: 7, isCorrect: false, word: "Pangolin", key: "pangolin"),
            .init(time: 11, isCorrect: true, word: "Timsah", key: "crocodile"),
        ]

        for index in 0..<copies {
            let id = UUID().uuidString
            let destination = videoURL(for: id)
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.copyItem(at: sourceURL, to: destination)
            let film = index / 2
            save(
                ReplayReel(
                    id: id,
                    createdAt: Calendar.current.date(
                        byAdding: .day, value: -(film + 1) * 2, to: .now
                    ) ?? .now,
                    matchID: "seed-\(film)",
                    sceneIndex: index % 2 + 1,
                    duration: source?.duration ?? 15,
                    deckIDs: [decks[film % decks.count]],
                    modeID: source?.modeID ?? "classic",
                    playerName: names[index % names.count],
                    marks: marks,
                    isPartial: false,
                    isPinned: index == 1
                )
            )
        }
        enforcePolicy(retention: AppSettingsStore.shared.replayRetention)
    }

    /// Kamera olmadan arşivi doldurmak için kısa bir renk şeridi. Gerçek
    /// kayıttan bağımsız: küçük resim, oynatıcı ve kota yine gerçek dosyayla
    /// çalışıyor.
    private static func makeSeedVideo() -> URL? {
        let url = directory.appending(path: "_seed.mov")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        let size = CGSize(width: 640, height: 360)
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return nil }
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: size.width,
                kCVPixelBufferHeightKey as String: size.height,
            ]
        )
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frames = 30 * 4
        for frame in 0..<frames {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
            guard let buffer = seedPixelBuffer(size: size, frame: frame) else { continue }
            let time = CMTime(value: CMTimeValue(frame), timescale: 30)
            adaptor.append(buffer, withPresentationTime: time)
        }
        input.markAsFinished()
        let done = DispatchSemaphore(value: 0)
        writer.finishWriting { done.signal() }
        done.wait()
        return writer.status == .completed ? url : nil
    }

    private static func seedPixelBuffer(size: CGSize, frame: Int) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            nil,
            &buffer
        )
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        let hue = CGFloat(frame % 90) / 90
        context.setFillColor(UIColor(hue: hue, saturation: 0.55, brightness: 0.35, alpha: 1).cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return buffer
    }
    #endif

    /// Videosu olmayan metadata (kayıt açılırken uygulama sonlandırıldı) ya da
    /// metadata'sı olmayan video (dosya yazıldı, tur sonu gelmedi) arşivde
    /// görünmeyeceği için sessizce yer kaplıyor.
    static func removeOrphans() {
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }

        let videos = Set(files.filter { $0.pathExtension == "mov" }.map(\.stem))
        let metadata = Set(files.filter { $0.pathExtension == "json" }.map(\.stem))

        for id in videos.symmetricDifference(metadata) {
            delete(id: id)
        }
    }
}

private extension URL {
    var stem: String { deletingPathExtension().lastPathComponent }
}

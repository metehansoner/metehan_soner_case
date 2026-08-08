#if DEBUG
import AVFoundation
import CoreGraphics
import Foundation


nonisolated final class SyntheticReplayCaptureEngine: ReplayCaptureEngine, @unchecked Sendable {

    private static let size = CGSize(width: 1280, height: 720)
    private static let fps: Int32 = 15

    private let queue = DispatchQueue(label: "com.charady.replay.synthetic")
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var timer: DispatchSourceTimer?
    private var events: ReplayCaptureEvents?
    private var frame: Int64 = 0

    let pausesCleanly = true

    func start(to url: URL, rotationAngle: CGFloat, events: ReplayCaptureEvents) {
        queue.async {
            guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else {
                events.didFinish(false)
                return
            }

            let input = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: Self.size.width,
                    AVVideoHeightKey: Self.size.height,
                ]
            )
            input.expectsMediaDataInRealTime = true
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: Self.size.width,
                    kCVPixelBufferHeightKey as String: Self.size.height,
                ]
            )
            guard writer.canAdd(input) else {
                events.didFinish(false)
                return
            }
            writer.add(input)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            self.writer = writer
            self.input = input
            self.adaptor = adaptor
            self.events = events
            self.frame = 0

            self.startTimer()
            events.didStart()
        }
    }

    func pause() { queue.async { self.timer?.cancel(); self.timer = nil } }

    func resume() { queue.async { self.startTimer() } }

    func stop() {
        queue.async {
            self.timer?.cancel()
            self.timer = nil
            guard let writer = self.writer, let input = self.input else { return }
            input.markAsFinished()
            let events = self.events
            self.events = nil


            nonisolated(unsafe) let finished = writer
            writer.finishWriting {
                events?.didFinish(finished.status == .completed)
            }
            self.writer = nil
            self.input = nil
            self.adaptor = nil
        }
    }

    func shutdown() {}

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: 1.0 / Double(Self.fps))
        timer.setEventHandler { [weak self] in self?.appendFrame() }
        timer.resume()
        self.timer = timer
    }

    private func appendFrame() {
        guard
            let adaptor, let input, input.isReadyForMoreMediaData,
            let pool = adaptor.pixelBufferPool
        else { return }

        var buffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
              let pixelBuffer = buffer else { return }

        draw(into: pixelBuffer)
        adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: frame, timescale: Self.fps))
        frame += 1
    }


    private func draw(into pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let base = CVPixelBufferGetBaseAddress(pixelBuffer),
            let context = CGContext(
                data: base,
                width: Int(Self.size.width),
                height: Int(Self.size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
            )
        else { return }

        let seconds = Double(frame) / Double(Self.fps)
        context.setFillColor(red: 0.24, green: 0.15, blue: 0.11, alpha: 1)
        context.fill(CGRect(origin: .zero, size: Self.size))

        context.setFillColor(red: 0.96, green: 0.66, blue: 0.23, alpha: 0.55)
        let x = (sin(seconds * 1.4) * 0.4 + 0.5) * Self.size.width
        context.fillEllipse(in: CGRect(x: x - 120, y: 200, width: 240, height: 240))

        context.setFillColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1)
        for band in 0..<24 {
            let y = Double(band) * 30 + seconds.truncatingRemainder(dividingBy: 1) * 30
            context.fill(CGRect(x: 0, y: y, width: 26, height: 18))
            context.fill(CGRect(x: Self.size.width - 26, y: y, width: 26, height: 18))
        }
    }
}
#endif

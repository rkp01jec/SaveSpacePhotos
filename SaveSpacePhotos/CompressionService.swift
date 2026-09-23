import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum CompressionService {
    static func compress(_ item: MediaItem, preset: CompressionPreset) async throws -> CompressionResult {
        try Task.checkCancellation()
        let outputURL: URL
        let warning: String

        switch item.type {
        case .photo:
            let encoded = try encodeImage(at: item.sourceURL, preset: preset)
            outputURL = encoded.url
            warning = encoded.warning
        case .video:
            outputURL = try await transcodeVideo(at: item.sourceURL, preset: preset)
            warning = "Live Photo pairing, cinematic metadata, edits, and some HDR or proprietary metadata are not guaranteed."
        }

        let outputBytes = try fileSize(at: outputURL)
        guard outputBytes > 0 else {
            throw CompressionError.invalidOutput
        }
        let minimumSavings = max(1024, item.originalBytes / 100)
        guard outputBytes + minimumSavings < item.originalBytes else {
            try? FileManager.default.removeItem(at: outputURL)
            throw CompressionError.notSmaller
        }

        return CompressionResult(
            id: item.id,
            source: item,
            outputURL: outputURL,
            outputBytes: outputBytes,
            outputType: item.type,
            warning: warning
        )
    }

    private static func encodeImage(at sourceURL: URL, preset: CompressionPreset) throws -> (url: URL, warning: String) {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CompressionError.invalidInput
        }

        let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil)
        let destinationTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        let outputType: CFString = destinationTypes.contains(UTType.heic.identifier)
            ? UTType.heic.identifier as CFString
            : UTType.jpeg.identifier as CFString
        let extensionName = outputType == UTType.heic.identifier as CFString ? "heic" : "jpg"
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("savespace-\(UUID().uuidString)")
            .appendingPathExtension(extensionName)

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            outputType,
            1,
            nil
        ) else {
            throw CompressionError.encodingFailed
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: preset.quality
        ]
        if metadata != nil {
            CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        } else {
            CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination),
              CGImageSourceCreateWithURL(outputURL as CFURL, nil) != nil else {
            try? FileManager.default.removeItem(at: outputURL)
            throw CompressionError.invalidOutput
        }

        return (
            outputURL,
            "Capture date, location, orientation, and standard camera metadata are copied when supported by Image I/O. Live Photo, depth, edit history, and proprietary metadata are not guaranteed."
        )
    }

    private static func transcodeVideo(at sourceURL: URL, preset: CompressionPreset) async throws -> URL {
        let asset = AVAsset(url: sourceURL)
        guard asset.isPlayable else { throw CompressionError.invalidInput }
        let availablePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let exportPreset = availablePresets.contains(preset.videoPreset)
            ? preset.videoPreset
            : (availablePresets.contains(AVAssetExportPresetHEVCHighestQuality)
                ? AVAssetExportPresetHEVCHighestQuality
                : AVAssetExportPresetMediumQuality)
        guard let session = AVAssetExportSession(asset: asset, presetName: exportPreset) else {
            throw CompressionError.encodingFailed
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("savespace-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = false
        session.metadata = asset.metadata

        let exportBox = ExportBox(session)
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                exportBox.session.exportAsynchronously {
                    switch exportBox.session.status {
                    case .completed:
                        continuation.resume()
                    case .cancelled:
                        continuation.resume(throwing: CancellationError())
                    default:
                        continuation.resume(throwing: exportBox.session.error ?? CompressionError.encodingFailed)
                    }
                }
            }
        } onCancel: {
            exportBox.session.cancelExport()
        }

        guard FileManager.default.fileExists(atPath: outputURL.path),
              AVAsset(url: outputURL).isPlayable else {
            try? FileManager.default.removeItem(at: outputURL)
            throw CompressionError.invalidOutput
        }
        return outputURL
    }

    private static func fileSize(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? NSNumber else { throw CompressionError.invalidOutput }
        return size.intValue
    }
}

private final class ExportBox: @unchecked Sendable {
    let session: AVAssetExportSession

    init(_ session: AVAssetExportSession) {
        self.session = session
    }
}

enum CompressionError: LocalizedError {
    case invalidInput
    case encodingFailed
    case invalidOutput
    case notSmaller

    var errorDescription: String? {
        switch self {
        case .invalidInput: "The selected media is unavailable or unsupported."
        case .encodingFailed: "The media could not be encoded."
        case .invalidOutput: "The compressed output could not be verified."
        case .notSmaller: "Compression would not produce meaningful storage savings."
        }
    }
}

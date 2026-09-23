import Foundation
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct MediaItem: Identifiable {
    let id: String
    let pickerItem: PhotosPickerItem
    let type: MediaType
    let sourceURL: URL
    let preview: UIImage?
    let originalBytes: Int
}

enum MediaType: String {
    case photo = "Photo"
    case video = "Video"
}

enum CompressionPreset: String, CaseIterable, Identifiable {
    case maximumQuality = "Maximum quality"
    case balanced = "Balanced"
    case maximumSavings = "Maximum savings"

    var id: String { rawValue }

    var quality: CGFloat {
        switch self {
        case .maximumQuality: 0.88
        case .balanced: 0.72
        case .maximumSavings: 0.52
        }
    }

    var videoPreset: String {
        switch self {
        case .maximumQuality: AVAssetExportPresetHEVCHighestQuality
        case .balanced: AVAssetExportPresetHEVC1920x1080
        case .maximumSavings: AVAssetExportPresetMediumQuality
        }
    }

    var detail: String {
        switch self {
        case .maximumQuality: "Best visual quality with moderate savings"
        case .balanced: "A practical balance of quality and storage"
        case .maximumSavings: "Smallest files with more visible compression"
        }
    }
}

struct CompressionResult: Identifiable {
    let id: String
    let source: MediaItem
    let outputURL: URL
    let outputBytes: Int
    let outputType: MediaType
    let warning: String?

    var savings: Int { max(source.originalBytes - outputBytes, 0) }
    var savingsPercent: Int {
        guard source.originalBytes > 0 else { return 0 }
        return Int((Double(savings) / Double(source.originalBytes) * 100).rounded())
    }
}

enum CompressionOutcome: Identifiable {
    case success(CompressionResult)
    case skipped(id: String, name: String, reason: String)
    case failed(id: String, name: String, reason: String)

    var id: String {
        switch self {
        case .success(let result): result.id
        case .skipped(let id, _, _), .failed(let id, _, _): id
        }
    }
}

enum AppStage {
    case onboarding
    case selecting
    case processing
    case results
}

func formattedBytes(_ bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

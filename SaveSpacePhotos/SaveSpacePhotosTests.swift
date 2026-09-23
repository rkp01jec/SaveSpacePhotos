import XCTest
import AVFoundation
import PhotosUI
import AVFoundation
import PhotosUI
import AVFoundation
import PhotosUI
import SwiftUI
import XCTest
import AVFoundation
import PhotosUI
import SwiftUI

@testable import SaveSpacePhotos

final class SaveSpacePhotosTests: XCTestCase {

    func testCompressionPresetValues() {
        XCTAssertEqual(CompressionPreset.maximumQuality.quality, 0.88)
        XCTAssertEqual(CompressionPreset.balanced.quality, 0.72)
        XCTAssertEqual(CompressionPreset.maximumSavings.quality, 0.52)

        XCTAssertEqual(CompressionPreset.maximumQuality.videoPreset, "AVAssetExportPresetHEVCHighestQuality")
        XCTAssertEqual(CompressionPreset.balanced.videoPreset, "AVAssetExportPresetHEVC1920x1080")
        XCTAssertEqual(CompressionPreset.maximumSavings.videoPreset, "AVAssetExportPresetMediumQuality")

        for preset in CompressionPreset.allCases {
            XCTAssertFalse(preset.detail.isEmpty)
        }
    }

    func testCompressionResultSavingsCalculation() {
        let dummyPickerItem = PhotosPickerItem(itemIdentifier: "test-item")
        let sourceItem = MediaItem(
            id: "test-1",
            pickerItem: dummyPickerItem,
            type: .photo,
            sourceURL: URL(fileURLWithPath: "/tmp/source.jpg"),
            preview: nil,
            originalBytes: 10_000_000 // 10 MB
        )

        let result = CompressionResult(
            id: "result-1",
            source: sourceItem,
            outputURL: URL(fileURLWithPath: "/tmp/output.jpg"),
            outputBytes: 4_000_000, // 4 MB
            outputType: .photo,
            warning: nil
        )

        XCTAssertEqual(result.savings, 6_000_000) // 6 MB saved
        XCTAssertEqual(result.savingsPercent, 60) // 60% savings
    }

    func testCompressionResultDoesNotReportSavingsWhenOutputIsLarger() {
        let dummyPickerItem = PhotosPickerItem(itemIdentifier: "test-item")
        let sourceItem = MediaItem(
            id: "test-2",
            pickerItem: dummyPickerItem,
            type: .photo,
            sourceURL: URL(fileURLWithPath: "/tmp/source.jpg"),
            preview: nil,
            originalBytes: 4_000_000
        )

        let result = CompressionResult(
            id: "result-2",
            source: sourceItem,
            outputURL: URL(fileURLWithPath: "/tmp/output.jpg"),
            outputBytes: 5_000_000,
            outputType: .photo,
            warning: nil
        )

        XCTAssertEqual(result.savings, 0)
        XCTAssertEqual(result.savingsPercent, 0)
    }

    func testFormattedBytesUtility() {
        let formattedZero = formattedBytes(0)
        XCTAssertTrue(formattedZero.contains("0") || formattedZero.contains("Zero"))

        let formattedMB = formattedBytes(5_242_880) // 5 MB
        XCTAssertTrue(formattedMB.contains("5") || formattedMB.contains("MB"))
    }
}

# App Requirements: SaveSpace Photos

## 1. Product Overview

**SaveSpace Photos** is an iOS app that creates smaller copies of photos and videos while leaving the original media untouched. The app processes media locally on the device and preserves standard user-visible metadata wherever the file format supports it.

### Recommended tagline

> Compress photos and videos. Keep the memories.

### App Store subtitle

> Save storage without losing your memories.

## 2. Product Goals

- Reduce the storage size of selected photos and videos.
- Preserve standard metadata, including capture date, location, orientation, and camera details where supported.
- Never modify or delete original media automatically.
- Give users clear visibility into expected and actual storage savings.
- Keep media processing private by performing it on-device.
- Let users save verified compressed copies into Photos.

## 3. Target Users

- iPhone users with limited or nearly full storage.
- Users who want to archive or share smaller media copies.
- Users who want compression without losing dates, locations, and camera information.

## 4. MVP Scope

### In scope

- Request permission to access the user's Photos library.
- Select photos and videos using the system photo picker.
- Display selected item count and original total size.
- Compress still images into an appropriate modern format, preferably HEIF/HEIC where supported.
- Compress videos using HEVC/H.265 where supported.
- Offer simple compression presets:
  - **Maximum quality**
  - **Balanced**
  - **Maximum savings**
- Preserve supported standard metadata.
- Show estimated savings before processing.
- Process media locally on-device.
- Show processing progress and allow cancellation.
- Verify each output before presenting it as complete.
- Preview compressed results and compare original versus compressed size.
- Save compressed copies to Photos.
- Create or use a dedicated Photos album named **SaveSpace Photos**.
- Keep originals unchanged.
- Avoid creating a duplicate compressed copy when the same original and settings were already processed.

### Out of scope for MVP

- Automatic deletion of originals.
- Cloud upload or server-side processing.
- Full photo-library scanning without user selection.
- Editing photos or videos beyond compression and resizing.
- Guaranteed preservation of proprietary or undocumented metadata.
- Complete support for Live Photos, depth data, cinematic video, and complex edit history.
- Background processing that continues indefinitely after the app is closed.

## 5. Functional Requirements

### 5.1 Onboarding and permissions

- Explain why Photos access is needed before requesting permission.
- Support the limited Photos access mode provided by iOS.
- Explain that media is processed locally and is not uploaded.
- Show an actionable message when permission is denied or restricted.

### 5.2 Media selection

- Allow users to select photos, videos, or both.
- Display thumbnails, media type, duration for videos, and original file size when available.
- Allow users to review and remove selected items before processing.
- Exclude unsupported or unavailable assets with a clear reason.

### 5.3 Compression settings

- Provide a default **Balanced** preset.
- Let users choose a preset before processing.
- Show the expected tradeoff between quality and storage savings.
- Preserve the original pixel dimensions unless the selected preset requires resizing.
- Avoid processing when the output is unlikely to be smaller than the original.

### 5.4 Metadata preservation

The app must attempt to preserve:

- Capture date and time
- GPS location
- Image orientation
- Camera make and model
- Lens and exposure information when supported
- Video creation date and supported location metadata

The app must not claim that every metadata field is preserved. The result screen must disclose when a media type or format may lose:

- Live Photo pairing
- Depth or portrait data
- Cinematic metadata
- Edit history
- Proprietary maker notes
- Unsupported HDR or color-profile information

### 5.5 Processing

- Process one or more selected assets in a controlled queue.
- Show overall progress and the current item.
- Allow cancellation without deleting originals or partial user-created results.
- Handle insufficient storage, unavailable assets, unsupported formats, and export failures explicitly.
- Use temporary files only during processing and clean them up after success or failure.

### 5.6 Results and verification

- Show original size, compressed size, and total savings.
- Show the number of successful, skipped, and failed items.
- Verify that each output can be decoded or played before saving it.
- Verify that expected metadata fields were carried into the output where technically supported.
- Allow users to preview compressed media before saving.

### 5.7 Saving to Photos

- Save compressed copies only after explicit user confirmation.
- Create the **SaveSpace Photos** album if it does not exist.
- Preserve the original Photos asset.
- Report assets that could not be saved and explain why.
- Avoid duplicate saves when the same verified output already exists.

## 6. Non-Functional Requirements

### Privacy and security

- All compression must occur on-device.
- Do not transmit photos, videos, metadata, or filenames to a server.
- Do not collect unnecessary personal data.
- Do not log GPS coordinates or other sensitive metadata.
- Use Apple's Photos permission and security APIs.

### Reliability

- A failed compression must not alter the original asset.
- A cancelled operation must leave the original asset intact.
- The app must recover cleanly from interruption or termination.
- Temporary files must be removed after processing completes or fails.

### Performance

- Display progress for operations involving multiple assets.
- Avoid loading an entire large video into memory.
- Use streaming or AVFoundation reader/writer APIs for large video files where appropriate.
- Keep the UI responsive during processing.

### Accessibility

- Support Dynamic Type.
- Provide VoiceOver labels for controls and progress.
- Do not rely on color alone to communicate status.
- Ensure buttons meet Apple's minimum touch target guidance.

## 7. Suggested iOS Technologies

- **Swift and SwiftUI** for the application UI.
- **Photos / PhotoKit** for asset access, metadata, albums, and saving copies.
- **PhotosUI / PHPickerViewController** for user-controlled media selection.
- **Image I/O** for image encoding and metadata handling.
- **AVFoundation** for video inspection, transcoding, playback, and metadata.
- **Uniform Type Identifiers** for supported file type detection.

## 8. Data Model

The app should maintain local processing records containing:

- Original Photos asset identifier
- Original media type
- Original file size
- Compression preset
- Output file type
- Output file size
- Processing date
- Verification status
- Saved Photos asset identifier, when available

Records should be stored locally and should not contain unnecessary copies of the user's media.

## 9. User Flow

1. User opens SaveSpace Photos.
2. User grants or confirms Photos access.
3. User taps **Select Media**.
4. User chooses photos and/or videos.
5. App displays the selection summary and compression preset.
6. User reviews estimated savings and starts compression.
7. App processes and verifies each item.
8. App shows previews, savings, and metadata warnings if applicable.
9. User taps **Save Compressed Copies**.
10. App saves copies to the **SaveSpace Photos** album.
11. App confirms that originals were not changed.

## 10. Acceptance Criteria

- A user can select at least one supported photo or video.
- The app creates a compressed copy without modifying the original.
- The compressed copy is smaller when the selected settings and source allow meaningful savings.
- The copy can be displayed or played successfully.
- Capture date, location, orientation, and supported camera metadata are retained and verified.
- The app clearly identifies metadata that may not be preserved.
- The app shows original size, output size, and savings.
- The user must explicitly confirm saving to Photos.
- Saved copies appear in the **SaveSpace Photos** album.
- Failed, cancelled, and unsupported operations provide clear user-facing feedback.

## 11. Future Enhancements

- Live Photo support with paired photo and video handling.
- Duplicate detection and storage recommendations.
- Batch compression by album or date range.
- A review screen for identifying originals that the user may optionally delete.
- Share-sheet integration.
- More granular quality, resolution, frame-rate, and bitrate controls.
- Widgets and storage trend reporting.

## 12. Naming Options

### Recommended

**SaveSpace Photos** — clear, friendly, and directly communicates the storage-saving purpose.

### Alternatives

- **Keepsake**
- **PocketVault**
- **Lighter**
- **Savor**
- **Memento Lite**
- **SnapSave**
- **Trimory**
- **SmallKeeps**

Before launch, check App Store availability, trademark conflicts, domain availability, and social media handles for the selected name.

## 13. User-Friendly Features

The app should make compression easy to understand, safe to use, and convenient for repeated use.

### Core experience

- Provide simple onboarding that explains local-only processing and confirms that original media will not be changed.
- Use one prominent **Select Media** action to open the system photo picker.
- Allow users to select photos, videos, or both.
- Provide a selection review screen with thumbnails, media type, file size, video duration, and remove actions.
- Use **Balanced** as the default compression preset and describe the quality-versus-savings tradeoff for every preset.
- Show estimated storage savings before processing begins.
- Show a progress bar, current item, remaining item count, and cancellation control during processing.
- Keep the interface responsive while media is being processed.

### Trust and clarity

- Show original size, compressed size, and total savings for every completed item and for the batch.
- Require explicit confirmation before saving compressed copies to Photos.
- Clearly state that originals remain unchanged.
- Show which metadata was preserved and which data may be lost, including Live Photo pairing, depth data, HDR information, and edit history.
- Allow users to preview compressed results before saving.
- Separate successful, skipped, and failed items in the results screen.
- Explain skipped and failed items using clear, actionable language.

### Convenience

- Automatically create and use the **SaveSpace Photos** album.
- Prevent duplicate processing when the same asset and settings were already processed.
- Prevent duplicate saves when the same verified output already exists.
- Provide **Select More Media** and **Save All** actions after processing.
- Remember the user's most recently selected compression preset.
- Skip files when compression would not produce meaningful storage savings, and explain why.
- Show a recent compression summary with total storage saved.

### Accessibility and appearance

- Support Dynamic Type and VoiceOver.
- Provide descriptive VoiceOver labels for thumbnails, controls, progress, warnings, and results.
- Do not rely on color alone to communicate status; include text and icons where appropriate.
- Use accessible contrast and Apple's recommended minimum touch target sizes.
- Support Light Mode and Dark Mode.

### Recommended first-use flow

1. User opens the app and reads a short explanation of local processing and original-file safety.
2. User taps **Select Media** and chooses photos or videos.
3. App shows the selected items, total size, and controls to remove items.
4. User chooses a compression preset and reviews estimated savings.
5. User starts compression and sees progress with the option to cancel.
6. App verifies each output and shows previews, sizes, savings, and metadata warnings.
7. User taps **Save Compressed Copies** and confirms the save operation.
8. App saves the verified copies to the **SaveSpace Photos** album and confirms that originals were not changed.

### Future user-friendly enhancements

- Share compressed copies directly from the results screen.
- Select media by album, date range, or media type.
- Detect visually identical or duplicate media.
- Provide an optional review workflow for deleting originals, always requiring explicit confirmation.
- Add Live Photo support with paired photo and video handling.
- Offer advanced controls for resolution, bitrate, frame rate, and quality.

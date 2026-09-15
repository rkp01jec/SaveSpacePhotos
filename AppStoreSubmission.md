# SaveSpace Photos App Store Submission

## App identity

- App name: SaveSpace Photos
- Subtitle: Save storage without losing your memories.
- Bundle ID: `com.savespace.photos`
- Suggested SKU: `savespace-photos-ios`
- Primary category: Photo & Video
- Secondary category: Utilities
- Platform: iPhone and iPad
- Minimum OS: iOS 17.0
- Version: 1.0
- Build: 1
- Copyright: Replace with the legal rights holder and year before submission.

## Promotional text

Compress photos and videos on your device while keeping the originals untouched. Review savings, understand metadata tradeoffs, and save verified copies to Photos.

## App Store description

SaveSpace Photos helps you create smaller copies of photos and videos without changing your originals.

Select the media you want to compress, choose a quality preset, review the expected savings, and inspect the verified results before saving. Processing happens locally on your device, so your photos, videos, and metadata are not uploaded to a server.

Features:

- Select photos and videos with Apple's Photos picker.
- Choose Maximum quality, Balanced, or Maximum savings.
- See original size, compressed size, and storage savings.
- Compress photos to HEIF when supported and videos to HEVC when supported.
- Review metadata preservation notes and format limitations.
- Cancel processing without changing original media.
- Preview verified compressed copies before saving.
- Save copies to a dedicated SaveSpace Photos album.
- Keep original Photos assets unchanged.

SaveSpace Photos does not automatically delete originals. You decide what to save, and your original media stays safe.

## Keywords

photo compressor,video compressor,save storage,photo storage,video storage,HEIF,HEVC,local compression

Keep keywords within Apple's 100-character limit after final editing. Do not repeat words unnecessarily.

## What's New in This Version

- Initial release.
- Local photo and video compression with selectable quality presets.
- Verified results and explicit save confirmation.

## App Review notes

SaveSpace Photos processes selected media locally on the device. It does not use accounts, cloud uploads, analytics, advertising, or tracking.

Test flow:

1. Launch the app.
2. Tap Select media and grant Photos access.
3. Choose one or more photos or videos.
4. Choose a compression preset.
5. Tap Compress.
6. Review verified results and metadata warnings.
7. Tap Save compressed copies and confirm.
8. Check the SaveSpace Photos album in Photos.

The app never modifies or deletes the original media. A sample photo and video should be included in the App Review device's Photos library for testing.

Known limitations for this release:

- Live Photo pairing, depth data, cinematic metadata, edit history, proprietary maker notes, and some HDR/color-profile information are not guaranteed.
- If compression would not produce meaningful savings, an item is skipped and explained.

## Privacy answers for App Store Connect

### Data collection

- Does the app collect data? No.
- Does the app track users? No.
- Does the app use third-party advertising or analytics? No.
- Are photos or videos uploaded? No.
- Are filenames, locations, or metadata sent to a server? No.

Photos and videos are user-selected content processed locally for the app's core function. Do not declare them as collected or linked data when completing the privacy questionnaire if the app remains local-only.

### Required permission explanation

Photos access is used so the user can select media for local compression and save compressed copies back to Photos. Original media is not modified or deleted automatically.

## Export compliance

The app does not implement custom encryption or network communications. Answer Apple's export-compliance questions according to the final binary and current App Store Connect questionnaire.

## Required App Store assets

- App icon: provide a finished 1024×1024 PNG through the Xcode AppIcon asset catalog.
- iPhone screenshots: capture the real app on a supported 6.5-inch or 6.7-inch simulator/device.
- iPad screenshots: capture the real app on a supported 12.9-inch or 13-inch iPad simulator/device if iPad is included in the target device family.
- Screenshots should show onboarding, media selection, compression progress, and verified results.
- Do not use placeholder UI, debug logs, or simulator chrome in uploaded screenshots.

## Before clicking Submit for Review

- Replace the copyright placeholder.
- Confirm the final product name is available and trademark-safe.
- Add the final app icon.
- Create an App Store Connect app record using bundle ID `com.savespace.photos`.
- Select the correct signing team and distribution certificate in Xcode.
- Archive a Release build and upload it from Organizer.
- Test on a physical device, including Photos permission, limited access, full access, cancellation, low storage, video compression, and saving to the album.
- Confirm the App Store privacy questionnaire matches the final binary.
- Confirm the support URL and privacy policy URL are live.

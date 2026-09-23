# SaveSpace Photos iOS App Skill

## Goal

Build and maintain a privacy-first SwiftUI iOS app that creates smaller copies of photos and videos while leaving original Photos assets unchanged. All media processing must happen locally on the device.

## Primary app metadata

- App name: SaveSpace Photos
- Bundle identifier: com.savespace.photos
- Target platform: iOS
- Language: Swift
- UI: SwiftUI
- Minimum deployment target: iOS 17.0
- Dependencies: Apple system frameworks only

## Project structure

```text
ProjectRoot/
├── PHOTO_COMPRESSION_APP_REQUIREMENTS.md
├── AGENT_SKILL.md
├── SaveSpacePhotos.xcodeproj/
└── SaveSpacePhotos/
  ├── SaveSpacePhotosApp.swift
  ├── ContentView.swift
  ├── CompressionModels.swift
  ├── PhotoLibraryService.swift
  └── Info.plist
```

## Required Apple frameworks

- SwiftUI for the user interface.
- PhotosUI and PHPicker-backed `PhotosPicker` for user-controlled selection.
- PhotoKit for permissions, asset saving, and the `SaveSpace Photos` album.
- Image I/O for image encoding and metadata handling.
- AVFoundation for video inspection and transcoding.
- UniformTypeIdentifiers for media type detection.

Do not add third-party dependencies unless the requirements explicitly change.

## App behavior

### Onboarding

- Explain that compression is performed locally and media is not uploaded.
- Explain that originals are never modified or deleted automatically.
- Request Photos access only after explaining why it is needed.
- Handle denied, restricted, and limited Photos access with actionable feedback.

### Media selection

- Allow photos, videos, or both to be selected with the system photo picker.
- Show thumbnails, media type, video duration, original file size, and selected item count when available.
- Allow users to review and remove selected items before processing.
- Exclude unsupported or unavailable assets with a clear reason.

### Compression

- Default to the Balanced preset.
- Offer Maximum quality, Balanced, and Maximum savings presets.
- Preserve original dimensions unless a preset requires resizing.
- Prefer HEIF/HEIC for still images where supported.
- Prefer HEVC/H.265 for videos where supported.
- Avoid processing when the output is unlikely to be smaller than the source.
- Use temporary files and clean them up after success, cancellation, or failure.
- Keep the interface responsive and avoid loading entire large videos into memory.

### Results and saving

- Show estimated savings before processing.
- Show progress, current item, remaining count, and cancellation controls.
- Verify every output can be decoded or played before presenting it as complete.
- Show original size, compressed size, item savings, and total savings.
- Separate successful, skipped, and failed items with plain-language explanations.
- Preview compressed results before saving.
- Require explicit confirmation before saving copies to Photos.
- Create or reuse the `SaveSpace Photos` album.
- Prevent duplicate processing and duplicate saves when the same source and settings were already verified.
- Confirm that originals were not changed.

## Metadata and warnings

Attempt to preserve supported standard metadata:

- Capture date and time
- GPS location
- Orientation
- Camera make and model
- Lens and exposure information
- Video creation date and supported location metadata

Never claim that every metadata field is preserved. Clearly warn when a format or media type may lose Live Photo pairing, depth data, cinematic metadata, edit history, proprietary maker notes, HDR information, or color-profile information.

## Local data

Processing records may store the original asset identifier, media type, source size, preset, output type and size, processing date, verification status, and saved asset identifier. Do not store unnecessary media copies or sensitive metadata such as GPS coordinates in logs.

## UI and accessibility

- Use a clear flow: onboarding, selection, settings, processing, results, save confirmation.
- Use Balanced as the visible default preset.
- Support Dynamic Type, VoiceOver, Light Mode, and Dark Mode.
- Provide descriptive accessibility labels for media, controls, progress, warnings, and results.
- Do not communicate status by color alone.
- Use accessible contrast and Apple's minimum touch target guidance.
- Keep controls large, direct, and understandable without instructional walls of text.

## Privacy and safety rules

- Never upload photos, videos, filenames, or metadata.
- Never modify or delete original Photos assets automatically.
- Never log GPS coordinates or other sensitive metadata.
- Cancellation and failure must leave originals intact.
- Explicitly report insufficient storage, unavailable assets, unsupported formats, and export failures.

## Implementation priorities

1. Keep the current project buildable in Xcode and on the iOS Simulator.
2. Preserve the existing SwiftUI navigation and user flow when extending features.
3. Implement real image and video compression before polishing secondary UI.
4. Add focused tests for compression settings, savings calculations, duplicate detection, cancellation, and metadata verification.
5. Validate on-device Photos permission and saving behavior before App Store preparation.

## Validation checklist

- Xcode project builds for the iOS Simulator.
- The bundle identifier is `com.savespace.photos`.
- `Info.plist` contains Photos read and add usage descriptions.
- Photos selection works with limited access.
- Original assets remain unchanged after processing and saving.
- Image and video outputs can be decoded or played.
- Output sizes and savings are accurate.
- Metadata warnings are shown where preservation is not guaranteed.
- Cancellation and failures clean up temporary files.
- Saved copies appear in the `SaveSpace Photos` album.
- Dynamic Type and VoiceOver labels are checked on the main workflow.
# Grade1Math iOS App Skill

## Goal
Create a colorful, dependency-free SwiftUI iOS starter app for first-grade math practice with a polished home screen, a quiz screen, progress tracking, and local persistence. Keep the project ready to open in Xcode and suitable for App Store preparation.

## Primary app metadata
- App name: Grade1MathLearn or Grade1Math
- Bundle identifier: com.mainapp.akp.Grade1Math
- Target platform: iOS
- Language: Swift
- UI: SwiftUI
- Persistence: UserDefaults / AppStorage
- Dependencies: none

## Suggested project structure
```
ProjectRoot/
├── README.md
├── .github/
│   └── workflows/
│       └── pages.yml
├── docs/
│   └── index.html
├── Grade1Math/
│   ├── Grade1MathApp.swift
│   ├── Info.plist
│   ├── PrivacyInfo.xcprivacy
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   ├── Models/
│   │   ├── MathQuestion.swift
│   │   ├── SampleQuestions.swift
│   │   ├── ProgressStore.swift
│   │   └── StudentProfile.swift
│   └── Views/
│       ├── HomeView.swift
│       ├── PracticeView.swift
│       └── ScoreProgressView.swift
├── Grade1Math.xcodeproj/
├── Grade1MathTests/
│   └── Grade1MathTests.swift
├── AppStoreAssets/
│   ├── AppStoreListing.md
│   ├── AppStoreConnectSubmission.md
│   ├── metadata.json
│   ├── PrivacyManifest.xcprivacy
│   ├── ScreenshotCaptureGuide.md
│   └── Screenshots/
│       ├── iPhone-6.5/
│       │   ├── home-1284x2778.png
│       │   └── question-1284x2778.png
│       └── iPad-12.9/
│           ├── home-2048x2732.png
│           └── question-2048x2732.png
└── .gitignore
```

## App behavior
### Home screen
- Personalized student name
- Greeting text such as “Hi, Math star!”
- Start Practice button
- Progress cards for correct answers, answered questions, best quiz score
- Friendly tips and feature list

### Quiz/practice screen
- Randomized first-grade math questions
- Categories such as:
  - mixed
  - addition
  - subtraction
  - comparison
- Large colored answer buttons
- Immediate feedback after each answer
- Optional speech read-aloud for question + answer choices
- Celebration sound for correct answers and milestone checkpoints
- Wrong-answer feedback with explanation
- Quiz ends after 10 questions

### Persistence
Store values locally with AppStorage or UserDefaults:
- student name
- total correct
- total answered
- best score
- sound setting
- read-aloud setting

## UI styling direction
- Warm, playful palette: purple, pink, orange, blue, green
- Rounded cards and large type
- Encouraging gradients and friendly geometry
- All text should be readable and child-friendly
- Keep large tap targets for young users

## Support and privacy page
Use a lightweight static HTML page hosted on GitHub Pages or a shared support repository.

Example URLs:
- Support: https://rkp01jec.github.io/app-support/grade1math/support.html
- Privacy: https://rkp01jec.github.io/app-support/grade1math/privacy-policy.html

Required page content:
- app support overview
- FAQ such as how to start practicing
- device and age guidance
- clear local-only storage statement
- no accounts, analytics, advertising, or tracking
- contact path to issue tracker or support email

## App Store screenshot requirements
### iPhone
- Use 6.5-inch screen capture
- Accepted upload size: 1284 x 2778
- Also acceptable: 2688 x 1242, 2778 x 1284

### iPad
- Use 12.9-inch iPad screen capture
- Required size: 2048 x 2732
- Also accepted: 2732 x 2048

### Screenshot set
Prepare at least:
- home screen
- practice/question screen
- optional summary/score screen

Capture the real app screens in the simulator with the app running from the correct route.
Always terminate the existing app before launching a screenshot build if switching temporary routes.

## README content
Include:
- project overview
- features list
- setup and Xcode instructions
- bundle identifier
- support/privacy URLs
- app store metadata notes
- screenshot guidance
- notes about local-only persistence and no network services

## Validation checklist
- Xcode project builds in simulator
- Info.plist contains required app metadata
- bundle identifier matches com.mainapp.akp.Grade1Math
- PrivacyInfo.xcprivacy exists
- app icon asset is included
- screenshots pass required dimensions
- README and support page are aligned with app behavior

## Example commit message
- Add Grade1Math SwiftUI starter app

## Example final output
The completed project should be a clean SwiftUI starter app that runs in Xcode, uses no third-party dependencies, contains question generation, progress tracking, and supporting documentation, and is ready for App Store preparation.

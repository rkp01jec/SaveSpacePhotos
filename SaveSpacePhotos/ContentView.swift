import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit
import CoreHaptics

struct ContentView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var stage: AppStage = .onboarding
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var mediaItems: [MediaItem] = []
    @State private var results: [CompressionResult] = []
    @State private var outcomes: [CompressionOutcome] = []
    @State private var preset: CompressionPreset = .balanced
    @State private var isLoading = false
    @State private var progress = 0.0
    @State private var currentItem = ""
    @State private var showSaveConfirmation = false
    @State private var savedCount = 0
    @State private var processingTask: Task<Void, Never>?
    @State private var hapticEngine: CHHapticEngine? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                switch stage {
                case .onboarding: onboarding
                case .selecting: selection
                case .processing: processing
                case .results: resultView
                }
            }
            .navigationTitle("SaveSpace Photos")
            .navigationBarTitleDisplayMode(.inline)
            .alert(permissionAlertTitle, isPresented: permissionAlert) {
                if library.authorization == .denied {
                    Button("Open Settings") {
                        playHaptic()
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                Button("OK", role: .cancel) {
                    playHaptic()
                }
            } message: {
                Text(library.errorMessage ?? "Allow Photos access in Settings to continue.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(4)
            }
            .alert("Save compressed copies?", isPresented: $showSaveConfirmation) {
                Button("Save to Photos") {
                    playHaptic(type: "success")
                    Task { await saveResults() }
                }
                Button("Cancel", role: .cancel) {
                    playHaptic()
                }
            } message: {
                Text("Your original media will remain unchanged. Copies will be added to the SaveSpace Photos album.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(4)
            }
        }
        .task {
            library.refreshAuthorization()
            if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                hapticEngine = try? CHHapticEngine()
                try? hapticEngine?.start()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                library.refreshAuthorization()
            }
        }
    }

    private var permissionAlert: Binding<Bool> {
        Binding(get: { library.errorMessage != nil }, set: { if !$0 { library.errorMessage = nil } })
    }

    private var permissionAlertTitle: String {
        switch library.authorization {
        case .authorized, .limited:
            "Unable to load media"
        default:
            "Photos access needed"
        }
    }

    private var onboarding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("More room for the moments that matter.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Create smaller copies of your photos and videos on this device. Your originals stay exactly where they are.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
                    benefit(icon: "lock.shield.fill", title: "Private by design", detail: "Nothing is uploaded. Compression happens on your iPhone.")
                    benefit(icon: "arrow.down.right.and.arrow.up.left", title: "Keep the original", detail: "Compressed copies are saved separately after you confirm.")
                    benefit(icon: "chart.bar.xaxis", title: "See the difference", detail: "Review expected and actual storage savings before saving.")
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 3, y: 2)

                Button {
                    playHaptic()
                    Task {
                        if await library.requestAccessIfNeeded() {
                            stage = .selecting
                        }
                    }
                } label: {
                    Label("Select media", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(20)
        }
    }

    private var selection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose what to compress")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                PhotosPicker(selection: $pickerItems, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                    Label("Choose from Photos", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: pickerItems) { _, newItems in
                    Task { await loadItems(newItems) }
                }

                if isLoading {
                    ProgressView("Loading selection...")
                }
                if !mediaItems.isEmpty {
                    selectionSummary
                    presetPicker
                    Button {
                        playHaptic()
                        stage = .processing
                        processingTask = Task { await compress() }
                    } label: {
                        Label("Compress \(mediaItems.count) item\(mediaItems.count == 1 ? "" : "s")", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    ContentUnavailableView("No media selected", systemImage: "photo.stack", description: Text("Choose photos or videos to see them here.").font(.system(size: 13, weight: .regular)).foregroundColor(.secondary))
                        .tint(.secondary)
                }
            }
            .padding(20)
        }
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(mediaItems.count) items · \(formattedBytes(mediaItems.reduce(0) { $0 + $1.originalBytes }))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            ForEach(mediaItems) { item in
                HStack(spacing: 12) {
                    if let preview = item.preview {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "video.fill")
                            .frame(width: 56, height: 56)
                            .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading) {
                        Text(item.type.rawValue)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        Text(formattedBytes(item.originalBytes))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 3, y: 2)
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compression preset")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            Picker("Preset", selection: $preset) {
                ForEach(CompressionPreset.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(preset.detail)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
    }

    private var processing: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "arrow.down.circle.fill").font(.system(size: 58)).foregroundStyle(.tint)
            Text("Making smaller copies")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            ProgressView(value: progress)
            Text(currentItem)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            Text("Originals are safe and will not be changed.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
            Button("Cancel compression", role: .cancel) {
                playHaptic(type: "warning")
                cancelCompression()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(32)
    }

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your results")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(results.count) verified · \(skippedCount) skipped · \(failedCount) failed")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    stat(title: "Saved", value: formattedBytes(results.reduce(0) { $0 + $1.savings }))
                    stat(title: "Average", value: "\(averageSavings)%")
                }
                metadataNotes
                ForEach(results) { result in
                    HStack(spacing: 12) {
                        if result.outputType == .photo, let image = UIImage(contentsOfFile: result.outputURL.path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "video.fill")
                                .frame(width: 64, height: 64)
                                .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Verified copy")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            Text("\(formattedBytes(result.source.originalBytes)) → \(formattedBytes(result.outputBytes))")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                            if let warning = result.warning {
                                Text(warning)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.orange)
                            }
                        }
                        if skippedCount > 0 || failedCount > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Items not completed")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                ForEach(outcomes.compactMap { outcome -> String? in
                                    switch outcome {
                                    case .skipped(_, let name, let reason), .failed(_, let name, let reason):
                                        return "\(name): \(reason)"
                                    case .success: return nil
                                    }
                                }, id: \.self) { message in
                                    Text(message)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 3, y: 2)
                }
                Button {
                    playHaptic(type: "success")
                    showSaveConfirmation = true
                } label: {
                    Label(savedCount > 0 ? "Saved \(savedCount) copies" : "Save compressed copies", systemImage: savedCount > 0 ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(savedCount > 0)
                Button {
                    playHaptic()
                    reset()
                } label: {
                    Text("Compress more media")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .padding(4)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .padding(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 3, y: 2)
    }

    private var metadataNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Metadata and format notes", systemImage: "info.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            Text("Photos are encoded as HEIF when supported, otherwise JPEG. Videos are transcoded to HEVC when supported.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
            Text("Capture date, location, orientation, and standard camera metadata are copied where the format supports them. Live Photo pairing, depth or portrait data, HDR or color-profile information, edit history, and proprietary maker notes are not guaranteed.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
            Text("Your original Photos asset is never modified. Each output is decoded or played back by the system before it is shown as verified.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .padding(4)
        }
        .padding(16)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private var averageSavings: Int {
        guard !results.isEmpty else { return 0 }
        return results.map(\.savingsPercent).reduce(0, +) / results.count
    }

    private var skippedCount: Int {
        outcomes.reduce(into: 0) { count, outcome in
            if case .skipped = outcome { count += 1 }
        }
    }

    private var failedCount: Int {
        outcomes.reduce(into: 0) { count, outcome in
            if case .failed = outcome { count += 1 }
        }
    }

    private func loadItems(_ items: [PhotosPickerItem]) async {
        isLoading = true
        defer { isLoading = false }
        cleanupTemporaryFiles()
        var loaded: [MediaItem] = []
        var loadFailures = 0
        var loadedIdentifiers = Set<String>()
        for item in items {
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            let identifier = item.itemIdentifier ?? UUID().uuidString
            guard loadedIdentifiers.insert(identifier).inserted else { continue }
            let sourceURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("savespace-source-\(UUID().uuidString)")
                .appendingPathExtension(isVideo ? "mov" : "jpg")
            do {
                if let providerURL = try? await item.loadTransferable(type: URL.self) {
                    try FileManager.default.copyItem(at: providerURL, to: sourceURL)
                } else if let data = try? await item.loadTransferable(type: Data.self) {
                    try data.write(to: sourceURL, options: .atomic)
                } else {
                    throw CocoaError(.fileReadUnknown)
                }
                let bytes = (try FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.intValue ?? 0
                loaded.append(MediaItem(
                    id: identifier,
                    pickerItem: item,
                    type: isVideo ? .video : .photo,
                    sourceURL: sourceURL,
                    preview: isVideo ? nil : UIImage(contentsOfFile: sourceURL.path),
                    originalBytes: bytes
                ))
            } catch {
                loadFailures += 1
            }
        }
        mediaItems = loaded
        if loadFailures > 0 {
            library.errorMessage = "\(loadFailures) selected item\(loadFailures == 1 ? "" : "s") could not be loaded."
        }
    }

    private func compress() async {
        results = []
        outcomes = []
        for (index, item) in mediaItems.enumerated() {
            if Task.isCancelled { cleanupTemporaryFiles(); return }
            currentItem = "Processing item \(index + 1) of \(mediaItems.count)"
            progress = Double(index) / Double(mediaItems.count)
            do {
                let result = try await CompressionService.compress(item, preset: preset)
                outcomes.append(.success(result))
                results.append(result)
            } catch is CancellationError {
                cleanupTemporaryFiles()
                return
            } catch {
                if let compressionError = error as? CompressionError, case .notSmaller = compressionError {
                    outcomes.append(.skipped(id: item.id, name: item.type.rawValue, reason: compressionError.localizedDescription))
                } else {
                    outcomes.append(.failed(id: item.id, name: item.type.rawValue, reason: error.localizedDescription))
                }
            }
        }
        if Task.isCancelled { cleanupTemporaryFiles(); return }
        progress = 1
        currentItem = "Verifying outputs"
        stage = .results
        processingTask = nil
    }

    private func cancelCompression() {
        processingTask?.cancel()
        processingTask = nil
        cleanupTemporaryFiles()
        results = []
        progress = 0
        currentItem = ""
        stage = .selecting
    }

    private func saveResults() async {
        let report = await library.save(results)
        savedCount = report.savedCount
        if report.savedCount > 0 {
            cleanupTemporaryFiles()
        }
    }

    private func reset() {
        processingTask?.cancel()
        processingTask = nil
        cleanupTemporaryFiles()
        pickerItems = []
        mediaItems = []
        results = []
        outcomes = []
        savedCount = 0
        progress = 0
        stage = .selecting
    }

    private func cleanupTemporaryFiles() {
        for item in mediaItems {
            try? FileManager.default.removeItem(at: item.sourceURL)
        }
        for result in results {
            try? FileManager.default.removeItem(at: result.outputURL)
        }
    }

    private func playHaptic(type: String = "tap") {
        guard let hapticEngine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensity: Float = type == "success" ? 1.0 : (type == "warning" ? 0.5 : 0.3)
        let sharpness: Float = type == "success" ? 0.8 : 0.4
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {}
    }
}


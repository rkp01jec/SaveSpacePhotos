import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

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
            .alert("Photos access needed", isPresented: permissionAlert) {
                if library.authorization == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(library.errorMessage ?? "Allow Photos access in Settings to continue.")
            }
            .alert("Save compressed copies?", isPresented: $showSaveConfirmation) {
                Button("Save to Photos") { Task { await saveResults() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your original media will remain unchanged. Copies will be added to the SaveSpace Photos album.")
            }
        }
        .task {
            library.refreshAuthorization()
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

    private var onboarding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("More room for the moments that matter.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Create smaller copies of your photos and videos on this device. Your originals stay exactly where they are.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
                    benefit(icon: "lock.shield.fill", title: "Private by design", detail: "Nothing is uploaded. Compression happens on your iPhone.")
                    benefit(icon: "arrow.down.right.and.arrow.up.left", title: "Keep the original", detail: "Compressed copies are saved separately after you confirm.")
                    benefit(icon: "chart.bar.xaxis", title: "See the difference", detail: "Review expected and actual storage savings before saving.")
                }
                .padding(20)
                .background(.background, in: RoundedRectangle(cornerRadius: 20))

                Button {
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
                    .font(.title2.bold())
                PhotosPicker(selection: $pickerItems, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                    Label("Choose from Photos", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: pickerItems) { _, newItems in
                    Task { await loadItems(newItems) }
                }

                if isLoading { ProgressView("Loading selection...") }
                if !mediaItems.isEmpty {
                    selectionSummary
                    presetPicker
                    Button {
                        stage = .processing
                        processingTask = Task { await compress() }
                    } label: {
                        Label("Compress \(mediaItems.count) item\(mediaItems.count == 1 ? "" : "s")", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    ContentUnavailableView("No media selected", systemImage: "photo.on.rectangle", description: Text("Choose photos or videos to see them here."))
                }
            }
            .padding(20)
        }
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.headline)
                Spacer()
                Text("\(mediaItems.count) items · \(formattedBytes(mediaItems.reduce(0) { $0 + $1.originalBytes }))")
                    .foregroundStyle(.secondary)
            }
            ForEach(mediaItems) { item in
                HStack(spacing: 12) {
                    if let preview = item.preview { Image(uiImage: preview).resizable().scaledToFill().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10)) }
                    else { Image(systemName: "video.fill").frame(width: 56, height: 56).background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)) }
                    VStack(alignment: .leading) {
                        Text(item.type.rawValue).font(.subheadline.bold())
                        Text(formattedBytes(item.originalBytes)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compression preset").font(.headline)
            Picker("Preset", selection: $preset) {
                ForEach(CompressionPreset.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(preset.detail).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var processing: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "arrow.down.circle.fill").font(.system(size: 58)).foregroundStyle(.tint)
            Text("Making smaller copies").font(.title2.bold())
            ProgressView(value: progress)
            Text(currentItem).font(.subheadline).foregroundStyle(.secondary)
            Text("Originals are safe and will not be changed.").font(.caption).foregroundStyle(.secondary)
            Button("Cancel compression", role: .cancel) {
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
                    Text("Your results").font(.title.bold())
                    Text("\(results.count) verified · \(skippedCount) skipped · \(failedCount) failed")
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    stat(title: "Saved", value: formattedBytes(results.reduce(0) { $0 + $1.savings }))
                    stat(title: "Average", value: "\(averageSavings)%")
                }
                metadataNotes
                ForEach(results) { result in
                    HStack(spacing: 12) {
                        if result.outputType == .photo, let image = UIImage(contentsOfFile: result.outputURL.path) {
                            Image(uiImage: image).resizable().scaledToFill().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "video.fill").frame(width: 64, height: 64).background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Verified copy").font(.subheadline.bold())
                            Text("\(formattedBytes(result.source.originalBytes)) → \(formattedBytes(result.outputBytes))")
                                .font(.caption).foregroundStyle(.secondary)
                            if let warning = result.warning { Text(warning).font(.caption2).foregroundStyle(.orange) }
                        }
                        if skippedCount > 0 || failedCount > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Items not completed").font(.headline)
                                ForEach(outcomes.compactMap { outcome -> String? in
                                    switch outcome {
                                    case .skipped(_, let name, let reason), .failed(_, let name, let reason):
                                        return "\(name): \(reason)"
                                    case .success: return nil
                                    }
                                }, id: \.self) { message in
                                    Text(message).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))
                }
                Button { showSaveConfirmation = true } label: {
                    Label(savedCount > 0 ? "Saved \(savedCount) copies" : "Save compressed copies", systemImage: savedCount > 0 ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(savedCount > 0)
                Button("Compress more media") { reset() }.frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(.tint).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.bold()) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private var metadataNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Metadata and format notes", systemImage: "info.circle.fill")
                .font(.headline)
            Text("Photos are encoded as HEIF when supported, otherwise JPEG. Videos are transcoded to HEVC when supported.")
                .font(.subheadline)
            Text("Capture date, location, orientation, and standard camera metadata are copied where the format supports them. Live Photo pairing, depth or portrait data, HDR or color-profile information, edit history, and proprietary maker notes are not guaranteed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Your original Photos asset is never modified. Each output is decoded or played back by the system before it is shown as verified.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            guard let providerURL = try? await item.loadTransferable(type: URL.self) else {
                loadFailures += 1
                continue
            }
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            let identifier = item.itemIdentifier ?? UUID().uuidString
            guard loadedIdentifiers.insert(identifier).inserted else { continue }
            let sourceURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("savespace-source-\(UUID().uuidString)")
                .appendingPathExtension(providerURL.pathExtension)
            do {
                try FileManager.default.copyItem(at: providerURL, to: sourceURL)
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
        processingTask?.cancel(); processingTask = nil; cleanupTemporaryFiles(); pickerItems = []; mediaItems = []; results = []; outcomes = []; savedCount = 0; progress = 0; stage = .selecting
    }

    private func cleanupTemporaryFiles() {
        for item in mediaItems {
            try? FileManager.default.removeItem(at: item.sourceURL)
        }
        for result in results {
            try? FileManager.default.removeItem(at: result.outputURL)
        }
    }
}

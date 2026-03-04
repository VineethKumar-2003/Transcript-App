//
//  VideoPickerView.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

private struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext)

            try FileManager.default.copyItem(at: received.file, to: destination)
            return Self(url: destination)
        }
    }
}

struct VideoPickerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var navigate = false
    @State private var transcripts: [TranscriptSegment] = []

    @State private var progress: Double = 0
    @State private var isProcessing = false

    @State private var showFileImporter = false
    
    @State private var videoURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos
                ) {
                    Text("Pick Video From Photos")
                }

                Button("Pick Video From Files") {
                    showFileImporter = true
                }

                if isProcessing {

                    ProgressView(value: progress)
                        .padding()

                    Text("Transcribing \(Int(progress * 100))%")
                }
            }
            .navigationDestination(isPresented: $navigate) {
                TranscriptListView(
                    transcript: transcripts,
                    videoURL: videoURL
                )
            }
            .onChange(of: selectedItem) {
                Task { await loadVideo() }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.movie]
            ) { result in
                switch result {

                case let .success(url):
                    Task {

                        let access = url.startAccessingSecurityScopedResource()

                        defer {
                            if access {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        do {

                            let destination = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                                .appendingPathExtension(url.pathExtension)

                            try FileManager.default.copyItem(at: url, to: destination)

                            await processVideo(destination)

                        } catch {
                            print("File copy error:", error)
                        }
                    }

                case let .failure(error):
                    print(error)
                }
            }
        }
    }
    
    private func loadVideo() async {
        guard let item = selectedItem else { return }

        do {
            if let movie = try await item.loadTransferable(type: PickedMovie.self) {
                await processVideo(movie.url)
            }

        } catch {
            print(error)
        }
    }

    private func processVideo(_ url: URL) async {

        do {

            try await SpeechPermission.request()

            isProcessing = true
            progress = 0
            transcripts.removeAll()
            
            videoURL = url

            transcripts = try await TranscriptEngine.shared.transcribe(videoURL: url) { update in
                let total = max(update.total, 1)
                let value = Double(update.current) / Double(total)
                DispatchQueue.main.async {
                    progress = value
                }
            }

            progress = 1
            isProcessing = false
            navigate = true

        } catch {

            isProcessing = false
            print(error)
        }
    }
}

#Preview {
    VideoPickerView()
}

//
//  VideoPickerView.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPickerView: View {

    @State private var selectedItem: PhotosPickerItem?
    @State private var navigate = false
    @State private var transcripts: [TranscriptSegment] = []

    @State private var progress: Double = 0
    @State private var isProcessing = false

    @State private var showFileImporter = false

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
                TranscriptListView(transcript: transcripts)
            }
            .onChange(of: selectedItem) {
                Task {
                    await loadVideo()
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.movie]
            ) { result in

                switch result {

                case .success(let url):
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

                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    private func loadVideo() async {

        guard let item = selectedItem else { return }

        do {

            if let data = try await item.loadTransferable(type: Data.self) {

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mov")

                try data.write(to: url)

                await processVideo(url)
            }

        } catch {
            print(error)
        }
    }

    private func processVideo(_ url: URL) async {

        do {

            try await SpeechPermission.request()

            isProcessing = true

            transcripts = try await TranscriptEngine.shared.transcribe(videoURL: url) { update in

                progress = Double(update.current) / Double(update.total)

            }

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

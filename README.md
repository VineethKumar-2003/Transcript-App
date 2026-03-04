# Transcript App

A lightweight SwiftUI application that transcribes video files to text using on-device speech recognition.

This sample project demonstrates how to pick a video from the Photos library or the Files app, extract its audio, and convert spoken words into a time‑stamped transcript entirely on the device. It's ideal for learning Swift concurrency, working with `PhotosUI`, `AVFoundation`, and `Speech` frameworks, and building scalable MVVM‑style apps.

---

## Features

- Pick videos from Photos or Files
- On‑device speech recognition (no network required)
- Time‑stamped transcript segments
- Clean, modular architecture (SwiftUI + service layer)
- Modern Swift (async/await, singletons, `@State`)

---

## Architecture

The project follows a simple MVVM‑ish pattern with a service layer:

- `TranscriptApp` → application entry point
- `ContentView` → root view loading the picker
- `VideoPickerView` → view that handles video selection and state management
- `TranscriptService` → singleton handling audio extraction and speech recognition
- `TranscriptSegment` → model representing each piece of transcript
- `TranscriptListView` → displays the final transcript

For a visual overview, see [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## Requirements

- Xcode 15 +
- iOS 17 + (or your current deployment target)

> **Note:** Speech recognition requires real device testing; the simulator does not support `SFSpeechRecognizer`.

---

## Installation & Running

1. Clone the repository:
   ```bash
   git clone https://github.com/VineethKumar-2003/Transcript-App.git
   ```
2. Open `Transcript App/Transcript App.xcodeproj` in Xcode.
3. Select a real iOS device and build & run (`Cmd+R`).
4. Grant microphone and speech permissions when prompted.
5. Pick a video and watch the transcript appear.

---

## Usage

- Tap **"Pick Video From Photos"** or **"Pick Video From Files"**.
- Choose a video containing clear speech.
- The app will request voice recognition permission and process the file.
- After processing, you'll see a list of transcript segments with timestamps.

---

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

Created by Vineeth Kumar G. Feel free to reach out on GitHub for suggestions or help.

---

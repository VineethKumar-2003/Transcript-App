# Transcript App Architecture & Data Flow

```mermaid
graph TD
    A["TranscriptApp<br/>(Entry Point)"] --> B["ContentView<br/>(Wrapper)"]
    
    B --> C["VideoPickerView<br/>(Main UI)"]
    
    C -->|User Action| D["Video Selection<br/>(Photos/Files)"]
    
    D -->|loadVideo/<br/>processVideo| E["Load Video File<br/>(Save to Temp)"]
    
    E -->|Pass URL| F["TranscriptService<br/>(Shared Instance)"]
    
    F -->|1. Request Permission| G["SFSpeechRecognizer<br/>Permission Check"]
    
    G -->|Permission Granted| H["Extract Audio<br/>(AVAssetExportSession)"]
    
    H -->|Audio M4A File| I["Speech Recognition<br/>(SFSpeechURLRecognitionRequest)"]
    
    I -->|Process Result| J["Create TranscriptSegments<br/>(Model)"]
    
    J -->|Array Result| K["Return to VideoPickerView<br/>Segments Array"]
    
    K -->|Set State| L["Navigate to<br/>TranscriptListView"]
    
    L --> M["TranscriptListView<br/>(Display Results)"]
    
    M -->|Render| N["Show Transcript<br/>with Timestamps"]
    
    O["TranscriptSegment<br/>(Model)<br/>- id<br/>- text<br/>- startTime<br/>- duration"] -.->|Used by| J
    O -.->|Used by| M
    
    P["Key Features"]
    P -.->|Local Processing| G
    P -.->|On-Device Speech Rec| I
    P -.->|Async/Await| F
    
    style A fill:#e1f5ff
    style C fill:#fff3e0
    style F fill:#f3e5f5
    style M fill:#e8f5e9
    style O fill:#fff9c4
    style P fill:#fce4ec
```

## Architecture Overview

### Components

- **TranscriptApp**: Entry point of the application
- **ContentView**: Wrapper view that loads VideoPickerView
- **VideoPickerView**: Main UI component handling video selection and processing
- **TranscriptService**: Service layer managing speech recognition and audio extraction
- **TranscriptSegment**: Data model representing transcript portions with timing information
- **TranscriptListView**: Display layer showing transcribed content with timestamps

### Data Flow

1. User selects video from Photos library or Files app
2. Video file is loaded and temporarily stored
3. TranscriptService requests speech recognition permission
4. Audio is extracted from video in M4A format
5. On-device speech recognition processes the audio
6. Results are converted to TranscriptSegment objects
7. Navigation occurs to TranscriptListView
8. Segments are displayed with formatted timestamps

### Key Features

- **On-Device Processing**: All speech recognition happens locally without server calls
- **Async/Await Pattern**: Modern Swift concurrency for smooth UX
- **Singleton Service**: Shared instance pattern for TranscriptService
- **State Management**: Uses @State in VideoPickerView for reactive updates

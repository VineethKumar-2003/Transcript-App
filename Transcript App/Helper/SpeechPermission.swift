//
//  SpeechPermission.swift
//  Transcript App
//
//  Created by Vineeth Kumar G on 04/03/26.
//

import Speech

final class SpeechPermission {
    
    static func request() async throws {
        
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard status == .authorized else {
            throw NSError(domain: "SpeechPermission", code: 1)
        }
    }
}

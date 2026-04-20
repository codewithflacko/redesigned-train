import AVFoundation
import SwiftUI

class VoiceAnnouncer: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isMuted: Bool = false

    func announce(_ text: String) {
        guard !isMuted else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate  = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

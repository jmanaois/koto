import AVFoundation
import Observation

/// Reads Japanese aloud with the built-in iOS voice. Free and offline.
@Observable
final class Speech: NSObject {
    static let shared = Speech()

    /// What is being read right now, so its button can show a stop icon.
    private(set) var speakingText: String?

    private let synthesizer = AVSpeechSynthesizer()

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Reads `text` aloud, or stops if that same text is already being read.
    func toggle(_ text: String) {
        if speakingText == text {
            stop()
        } else {
            speak(text)
        }
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        // Play even with the ring/silent switch on, and lower other audio while speaking.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: Self.speakable(text))
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        let slower = UserDefaults.standard.object(forKey: AppSettings.slowSpeechKey) as? Bool ?? true
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (slower ? 0.8 : 1.0)
        speakingText = text
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speakingText = nil
    }

    /// Drops internet laughter (w, ww, 草 after a sentence) that the voice would read as letters,
    /// and emoji, which it reads out by name.
    private static func speakable(_ text: String) -> String {
        var result = text.unicodeScalars.filter { !$0.properties.isEmojiPresentation && $0.value != 0xFE0F }
            .reduce(into: "") { $0.unicodeScalars.append($1) }
        result = result.replacingOccurrences(of: "[wｗ]+(?=$|[\\s。！？!?、])", with: "", options: .regularExpression)
        return result
    }
}

extension Speech: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finished() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finished() }
    }

    private func finished() {
        if !synthesizer.isSpeaking {
            speakingText = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

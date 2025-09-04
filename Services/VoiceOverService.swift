import Foundation
import AVFoundation
import UIKit
import UserNotifications

/// TTS 및 VoiceOver 안내를 담당하는 싱글톤 서비스
final class VoiceOverService: NSObject {
    static let shared = VoiceOverService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        print("FeelinkApp VoiceOverService 초기화")
        configureSpeech()
    }
    
    /// AVAudioSession 및 SpeechSynthesizer 델리게이트 설정
    private func configureSpeech() {
        synthesizer.delegate = self
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.playback, options: [.mixWithOthers])
        } catch {
            print("FeelinkApp 오디오 세션 설정 오류: \(error)")
        }
    }
    
    /// VoiceOver 또는 TTS로 텍스트 읽기
    /// - Parameters:
    ///   - text: 읽을 문자열
    ///   - priority: VoiceOver 알림 우선순위 (기본 .announcement)
    func announce(_ text: String,
                  priority: UIAccessibility.Notification = .announcement) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: priority, argument: text)
        } else {
            speakText(text) // VoiceOver가 꺼져있으면 TTS로
        }
        print("FeelinkApp VoiceOver/TTS 안내 시도: \(text) (Priority: \(priority))")
    }
    
    /// ✅ 분석 결과 전용 안내 (간소화된 멘트 + 결과)
    /// 예: "분석되었습니다. 포메라니안 강아지입니다."
    func announceAnalysisResult(_ content: String) {
        let cleanMessage = "분석되었습니다. \(content)"
        announce(cleanMessage, priority: .screenChanged)
    }
    
    /// ✅ 챗봇 응답 전용 안내
    func announceChatResponse(_ response: String) {
        announce(response, priority: .announcement)
    }
    
    /// ✅ 음성 녹음 상태 안내
    /// - Parameter isRecording: true이면 녹음 시작 안내, false이면 종료 안내
    func announceRecordingState(_ isRecording: Bool) {
        let message = isRecording ? "음성 인식을 시작합니다. 질문해 주세요." : "음성 인식이 완료되었습니다."
        announce(message, priority: .screenChanged)
    }
    
    /// AVSpeechSynthesizer를 통해 텍스트 읽기
    private func speakText(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
                          ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    /// 푸시/로컬 알림 콘텐츠를 읽어주는 헬퍼
    func announceNotification(_ content: UNNotificationContent) {
        let message = "FeelinkApp 알림: \(content.title). \(content.body)"
        announce(message, priority: .screenChanged) // 중요 알림은 priority 높임
    }
    
    /// 진행 중인 읽기를 즉시 중단
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        print("FeelinkApp TTS 중단")
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceOverService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        print("FeelinkApp TTS 완료")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        print("FeelinkApp TTS 취소됨")
    }
}

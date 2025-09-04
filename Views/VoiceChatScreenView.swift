import SwiftUI

struct VoiceChatScreenView: View {
    let conversationId: String
    var onDismiss: () -> Void
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isListening = false
    @State private var isProcessing = false
    @State private var lastResponse = ""

    var body: some View {
        VStack {
            Spacer()
            Button(action: toggleListening) {
                Circle()
                    .fill(isListening ? Color.red : Color.blue)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                    )
            }
            if isProcessing { ProgressView("응답 처리 중...") }
            Spacer()
            Button("닫기", action: onDismiss)
        }
        .onAppear {
            VoiceOverService.shared.announce("AI 질문 화면입니다. 음성 버튼을 눌러 질문하세요.")
        }
    }

    private func toggleListening() {
        if isListening {
            speechService.stopRecording()
            isListening = false
        } else {
            isListening = true
            speechService.startRecording { result in
                isListening = false
                if case .success(let text) = result {
                    sendChat(text)
                }
            }
        }
    }

    private func sendChat(_ message: String) {
        isProcessing = true
        APIService.shared.sendChatMessage(message, analysisId: conversationId) { result in
            isProcessing = false
            if case .success(let res) = result {
                self.lastResponse = res.message
                VoiceOverService.shared.announce("분석되었습니다. \(res.message)")
            }
        }
    }
}

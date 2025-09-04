import SwiftUI
import Speech
import UIKit

// UIKit의 UILongPressGestureRecognizer를 SwiftUI에서 쓰기 위한 래퍼 뷰
struct TwoFingerLongPressView: UIViewRepresentable {
    var minimumPressDuration: CFTimeInterval = 0.1
    var onLongPressBegan: () -> Void
    var onLongPressEnded: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress)
        )
        longPress.minimumPressDuration = minimumPressDuration
        longPress.numberOfTouchesRequired = 2  // 두 손가락 롱프레스 지정
        view.addGestureRecognizer(longPress)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLongPressBegan: onLongPressBegan, onLongPressEnded: onLongPressEnded)
    }

    class Coordinator: NSObject {
        let onLongPressBegan: () -> Void
        let onLongPressEnded: () -> Void

        init(onLongPressBegan: @escaping () -> Void, onLongPressEnded: @escaping () -> Void) {
            self.onLongPressBegan = onLongPressBegan
            self.onLongPressEnded = onLongPressEnded
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                onLongPressBegan()
            case .ended, .cancelled, .failed:
                onLongPressEnded()
            default:
                break
            }
        }
    }
}

struct VoiceChatView: View {
    let analysisResult: AnalysisResult
    var screenshotImage: UIImage? // 스크린샷 이미지
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isListening = false
    @State private var recognizedText = ""
    @Binding var chatResponse: String
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            Color.clear
                .background(
                    TwoFingerLongPressView(
                        minimumPressDuration: 0.1,
                        onLongPressBegan: { startListening() },
                        onLongPressEnded: { stopListening() }
                    )
                )

            // 오버레이 UI
            Group {
                if isListening {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            Text("FeelinkApp 음성 인식 중...")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 100)
                    }
                }

                if isProcessing {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("응답 처리 중...")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }

    private func startListening() {
        guard !isListening && !isProcessing else { return }

        print("🎙️ FeelinkApp 음성 인식 시작")
        isListening = true
        recognizedText = ""

        // 홀드 시작 시 햅틱 피드백
        HapticService.shared.triggerLongPressHaptic()

        VoiceOverService.shared.announce("FeelinkApp 음성 인식을 시작합니다")

        speechService.startRecording { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    self.recognizedText = text
                    print("FeelinkApp 인식된 텍스트: \(text)")
                    self.sendChatMessage(text)
                    self.isListening = false
                case .failure(let error):
                    print("FeelinkApp 음성 인식 오류: \(error)")
                    if let nsError = error as? NSError,
                       nsError.domain == "SFSpeechRecognizerErrorDomain",
                       nsError.code == 301 {
                        print("FeelinkApp: 음성 인식 요청이 취소되었습니다 (예상된 동작)")
                    } else {
                        VoiceOverService.shared.announce("FeelinkApp 음성 인식에 실패했습니다")
                    }
                    self.isListening = false
                    self.isProcessing = false
                }
            }
        }
    }

    private func stopListening() {
        guard isListening else { return }

        print("FeelinkApp 음성 녹음 중단")
        isListening = false
        speechService.stopRecording()
    }

    private func sendChatMessage(_ message: String) {
        guard !message.isEmpty else { return }
        print("FeelinkApp 챗봇 메시지 전송: \(message)")
        isProcessing = true

        APIService.shared.sendChatMessage(
            message,
            analysisId: analysisResult.id,
            imageData: screenshotImage?.jpegData(compressionQuality: 0.8)
        ) { result in
            DispatchQueue.main.async {
                self.isProcessing = false

                switch result {
                case .success(let response):
                    print("FeelinkApp 챗봇 응답 받음: \(response.message)")
                    self.chatResponse = response.message
                    VoiceOverService.shared.announce("FeelinkApp 응답: \(response.message)")
                case .failure(let error):
                    print("FeelinkApp 챗봇 응답 오류: \(error)")
                    VoiceOverService.shared.announce("FeelinkApp 응답을 받아오는데 실패했습니다")
                }
            }
        }
    }
}

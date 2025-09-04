import SwiftUI

struct TestModeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var showVoiceChat = false
    @State private var showScreenshotResult = false
    @State private var testChatResponse: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("테스트 모드")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // ✅ 챗봇 알림 테스트 버튼 추가
                Button("챗봇 알림 테스트") {
                    testChatNotification()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("챗봇 기능이 포함된 알림 테스트")
                
                Button("알림 테스트") {
                    // Call the notification service
                    NotificationService.shared.showLocalNotification(
                        title: "테스트 알림",
                        body: "이것은 테스트 알림입니다."
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("테스트 알림 보내기")

                Button("갤러리 이미지 분석") {
                    showImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("갤러리에서 이미지 선택 후 분석")
                .sheet(isPresented: $showImagePicker) {
                    ImagePickerView()
                }

                Button("음성 분석 기능 테스트") {
                    showVoiceChat = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("음성 분석 기능 테스트 시작")
                .sheet(isPresented: $showVoiceChat) {
                    // VoiceChatView requires an AnalysisResult
                    // Create a dummy one for testing
                    VoiceChatView(analysisResult: AnalysisResult(
                        id: "test-voice-analysis",
                        timestamp: Date(),
                        summary: "음성 분석 테스트를 위한 더미 결과입니다.",
                        objects: [],
                        text: nil,
                        confidence: 1.0,
                        screenshotURL: nil,
                        appName: "테스트 앱"
                    ), chatResponse: $testChatResponse)
                }

                Button("스크린샷 결과 보기") {
                    showScreenshotResult = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("스크린샷 결과 화면 보기")
                .sheet(isPresented: $showScreenshotResult) {
                    ScreenshotResultView(analysisResult: nil, onDismiss: { showScreenshotResult = false })
                }

                Spacer()
            }
            .padding()
            .navigationTitle("테스트 모드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .accessibilityLabel("테스트 모드 닫기")
                }
            }
        }
    }
    
    // ✅ 챗봇 알림 테스트 함수
    private func testChatNotification() {
        NotificationService.shared.showBackendResponseNotification(
            response: "화면에서 노트북과 커피잔이 보입니다. 추가 질문이 있으시면 알림을 길게 눌러주세요.",
            analysisId: "test-chat-analysis-789"
        )
    }
}

struct TestModeView_Previews: PreviewProvider {
    static var previews: some View {
        TestModeView()
    }
}

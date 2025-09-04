import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.colorScheme) private var colorScheme // 현재 라이트/다크 모드 확인용

    // 분석 결과 화면 여부
    @State private var shouldShowScreenshotView = false
    @State private var analysisResult: AnalysisResult?
    // ✅ 추가: conversation_id 기반 대화 화면 여부
    @State private var conversationId: String?

    // 로그인 상태 플래그
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    // 회원가입 화면 표시 여부
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 시스템 배경색: 라이트/다크 자동 대응
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                Group {
                    // 1) 로그아웃 상태 → 로그인 화면
                    if !isUserLoggedIn {
                        LoginView(
                            onLoginSuccess: { isUserLoggedIn = true },
                            onSignupTap:    { showSignup = true }
                        )
                        .tint(.accentColor) // 버튼/링크 색은 시스템 틴트로
                        .toolbar(.hidden, for: .navigationBar)
                        .fullScreenCover(isPresented: $showSignup) {
                            SignupView(onSignupSuccess: {
                                // 회원가입 직후 자동 로그인
                                isUserLoggedIn = true
                                showSignup = false
                            })
                            .tint(.accentColor)
                        }

                    // 2) 로그인 완료 + 🔹conversation_id 기반 대화 화면 표시
                    } else if shouldShowScreenshotView, let convId = conversationId {
                        VoiceChatScreenView(
                            conversationId: convId,
                            onDismiss: {
                                shouldShowScreenshotView = false
                                conversationId = nil
                            }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                        .transition(.opacity.combined(with: .scale))

                    // 3) 로그인 완료 + 분석결과 화면
                    } else if shouldShowScreenshotView, let result = analysisResult {
                        ScreenshotResultView(
                            analysisResult: result,
                            onDismiss: {
                                shouldShowScreenshotView = false
                                analysisResult = nil
                            }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                        .transition(.opacity.combined(with: .scale))

                    // 4) 로그인 완료 + 카메라 플레이스홀더
                    } else {
                        ScreenshotResultView(
                            analysisResult: nil,
                            onDismiss: {
                                shouldShowScreenshotView = false
                                analysisResult = nil
                            }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal)
            }
            // 상태 변환시 자연스럽게
            .animation(.easeInOut(duration: 0.2), value: isUserLoggedIn)
            .animation(.easeInOut(duration: 0.2), value: shouldShowScreenshotView)
            .onReceive(NotificationCenter.default.publisher(for: .showFeelinkAnalysisResult)) { notification in
                if let id = notification.object as? String {
                    // conversation_id인지, analysisId인지 구분
                    if id.hasPrefix("conversation_") || id.contains("-") {
                        self.conversationId = id
                        self.analysisResult = nil
                        self.shouldShowScreenshotView = true
                    } else {
                        loadAnalysisResult(id)
                    }
                }
            }
            .onAppear {
                VoiceOverService.shared.announce("FeelinkApp 메인 화면입니다.")
            }
            // 접근성: 컬러 대비 자동 관리 (시스템 프리미티브 사용으로 충분)
        }
    }

    private func loadAnalysisResult(_ analysisId: String) {
        APIService.shared.getAnalysisResult(analysisId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analysis):
                    self.analysisResult = analysis
                    self.conversationId = nil
                    self.shouldShowScreenshotView = true
                case .failure:
                    VoiceOverService.shared.announce("분석 결과를 불러오는데 실패했습니다.")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(NotificationService.shared)
                .environment(\.colorScheme, .light)

            ContentView()
                .environmentObject(NotificationService.shared)
                .environment(\.colorScheme, .dark)
        }
    }
}

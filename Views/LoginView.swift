import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // 콜백
    var onLoginSuccess: () -> Void
    var onSignupTap:    () -> Void

    // 입력 상태
    @State private var email    = ""
    @State private var password = ""

    // 에러 알림
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTestModeView = false

    // 브랜드 색 (Assets의 AccentColor를 쓰는 게 가장 좋음)
    private let primaryColor = Color(red: 126/255, green: 200/255, blue: 255/255)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer().frame(height: 60)

                // 로고
                Text("Feelink")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(primaryColor)

                // 제목
                Text("로그인")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                // 이메일 / 비밀번호 입력
                VStack(spacing: 12) {
                    TextField("이메일을 입력하세요", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.username)
                        .submitLabel(.next)
                        .frame(height: 48)
                        .padding(.horizontal, 12)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(uiColor: .separator), lineWidth: 1)
                        )
                        .accessibilityLabel("이메일 입력란")

                    SecureField("비밀번호를 입력하세요", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .frame(height: 48)
                        .padding(.horizontal, 12)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(uiColor: .separator), lineWidth: 1)
                        )
                        .accessibilityLabel("비밀번호 입력란")
                }

                // 로그인 버튼
                Button {
                    signIn()
                } label: {
                    Text("로그인")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(primaryColor)
                .accessibilityLabel("이메일과 비밀번호로 로그인")

                // 구분선 + 또는
                HStack {
                    Divider().background(Color(uiColor: .separator))
                    Text("또는").foregroundStyle(.secondary)
                    Divider().background(Color(uiColor: .separator))
                }

                // 회원가입 버튼
                Button {
                    onSignupTap()
                } label: {
                    Text("회원가입")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(primaryColor)
                .accessibilityLabel("회원가입 화면으로 이동")

                // 소셜 로그인 버튼들
                VStack(spacing: 12) {
                    Button {
                        // TODO: 네이버 로그인
                    } label: {
                        HStack(spacing: 8) {
                            Image("naver_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("네이버 로그인")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 3/255, green: 199/255, blue: 90/255)) // 네이버 그린
                    .foregroundStyle(.white)
                    .accessibilityLabel("네이버 계정으로 로그인")

                    Button {
                        // TODO: 카카오 로그인
                    } label: {
                        HStack(spacing: 8) {
                            Image("kakao_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("카카오 로그인")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 1, green: 235/255, blue: 0)) // 카카오 옐로
                    .foregroundStyle(.black) // 카카오 가이드에 맞춰 블랙 유지
                    .accessibilityLabel("카카오 계정으로 로그인")
                }
                .padding(.top, 8)

                // New Test Mode Button
                Button {
                    showTestModeView = true
                } label: {
                    Text("테스트 모드")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple) // Using a distinct color for test mode
                .accessibilityLabel("테스트 모드 화면으로 이동")
                .sheet(isPresented: $showTestModeView) {
                    TestModeView() // This view will be created next
                }

                // 약관 안내
                Text("회원가입시 당사의 서비스 이용 약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground)) // 라이트/다크 자동
        .ignoresSafeArea(edges: .bottom)
        .alert("로그인 실패", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            onLoginSuccess()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(onLoginSuccess: {}, onSignupTap: {})
                .environment(\.colorScheme, .light)
            LoginView(onLoginSuccess: {}, onSignupTap: {})
                .environment(\.colorScheme, .dark)
        }
    }
}

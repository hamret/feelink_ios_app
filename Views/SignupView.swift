import SwiftUI
import FirebaseAuth   // 로그인·회원가입 로직
import FirebaseMessaging  // (필요 시) 푸시 토큰 연동

struct SignupView: View {
    // 회원가입 성공 콜백
    var onSignupSuccess: () -> Void

    // 입력 상태
    @State private var name     = ""
    @State private var phone    = ""
    @State private var email    = ""
    @State private var password = ""

    // 에러 상태
    @State private var showError = false
    @State private var errorMessage = ""

    // 브랜드 컬러 (Assets의 AccentColor 사용을 권장)
    private let primaryColor = Color(red: 126/255, green: 200/255, blue: 255/255)

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer().frame(height: 40)

                    // 로고
                    Text("Feelink")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundStyle(primaryColor)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 제목 / 부제
                    VStack(spacing: 4) {
                        Text("회원가입")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("다음 정보를 입력해주세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // 개인 정보 입력
                    SectionHeader("개인 정보 입력")

                    VStack(spacing: 12) {
                        TextField("이름", text: $name)
                            .textContentType(.name)
                            .submitLabel(.next)
                            .modifier(InputFieldStyle())
                            .accessibilityLabel("이름 입력란")

                        TextField("전화번호", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .submitLabel(.next)
                            .modifier(InputFieldStyle())
                            .accessibilityLabel("전화번호 입력란")
                    }

                    // 로그인 정보 입력
                    SectionHeader("로그인 정보 입력")

                    VStack(spacing: 12) {
                        TextField("이메일", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .submitLabel(.next)
                            .modifier(InputFieldStyle())
                            .accessibilityLabel("이메일 입력란")

                        SecureField("비밀번호", text: $password)
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .modifier(InputFieldStyle())
                            .accessibilityLabel("비밀번호 입력란")
                    }

                    // 회원가입 버튼
                    Button {
                        signUp()
                    } label: {
                        Text("회원가입")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryColor)
                    .accessibilityLabel("입력한 정보로 회원가입")
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground)) // 라이트/다크 자동 대응
            .navigationTitle("회원가입")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("닫기")
                }
            }
            .alert("회원가입 실패", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func signUp() {
        // 간단 유효성 체크 (원하면 강화 가능)
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "이름, 이메일, 비밀번호를 모두 입력해주세요."
            showError = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }

            // 필요 시: 프로필 업데이트(표시 이름)
            let change = Auth.auth().currentUser?.createProfileChangeRequest()
            change?.displayName = name
            change?.commitChanges(completion: nil)

            // 필요 시: FCM 토큰 연동
            // Messaging.messaging().token { token, _ in
            //     // 서버로 사용자-토큰 매핑 저장
            // }

            onSignupSuccess()
        }
    }
}

// MARK: - 공통 컴포넌트/스타일

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}

/// 텍스트필드 공통 스타일: 다크/라이트 자동 대응 배경 + 구분선
private struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 48)
            .padding(.horizontal, 12)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(uiColor: .separator), lineWidth: 1)
            )
            .foregroundStyle(.primary)
    }
}

// MARK: - 미리보기

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignupView(onSignupSuccess: {})
                .environment(\.colorScheme, .light)
            SignupView(onSignupSuccess: {})
                .environment(\.colorScheme, .dark)
        }
    }
}

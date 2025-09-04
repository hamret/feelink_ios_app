import SwiftUI

struct ShortcutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    let isFirstLaunch: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "shortcuts")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("FeelinkApp 단축어 설정")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("후면 더블탭으로 간편하게 스크린샷 분석을 시작하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        StepView(step: "1", title: "단축어 앱 열기", description: "iPhone의 단축어 앱 실행")
                        StepView(step: "2", title: "새 단축어 만들기", description: "우상단 '+' 버튼으로 생성")
                        StepView(step: "3", title: "액션 추가", description: "• 스크린샷 찍기\n• 웹에 요청\n• URL 열기")
                        StepView(step: "4", title: "후면 더블탭 설정", description: "설정 > 손쉬운 사용 > 터치 > 뒤로 탭하기에서 선택")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("웹 요청 URL:").font(.headline)
                        Text("https://feelink-back-g0djc8evend6crfe.koreacentral-01.azurewebsites.net/chat/start")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.all, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        Text("방법: POST / 폼 데이터").font(.caption)
                        Text("image_file = [스크린샷]").font(.caption)
                        Text("user_question = 이 이미지에 뭐가 보여?").font(.caption)
                        Text("URL 열기 → feelinkapp://screenshot-result").font(.caption)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(isFirstLaunch ? "환영합니다!" : "단축어 설정")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        if isFirstLaunch {
                            UserDefaults.standard.set(true, forKey: "hasShownFirstLaunchSetup")
                        }
                        dismiss()
                    }
                    .accessibilityLabel("단축어 설정 완료")
                }
            }
        }
    }
}

struct StepView: View {
    let step: String
    let title: String
    let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .fontWeight(.bold)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(description).font(.caption).foregroundColor(.gray)
            }
        }
    }
}

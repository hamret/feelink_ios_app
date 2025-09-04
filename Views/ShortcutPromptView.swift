import SwiftUI

struct ShortcutPromptView: View {
    @Binding var isPresented: Bool
    // 여기에 실제 단축어 URL을 넣으세요.
    let shortcutURL = URL(string: "https://www.icloud.com/shortcuts/b9be7529fdf74754a28e2b4b01d7ab91")!

    var body: some View {
        VStack(spacing: 20) {
            Text("단축어를 추가하시겠습니까?")
                .font(.title2)
                .multilineTextAlignment(.center)

            Button("단축어 열기") {
                UIApplication.shared.open(shortcutURL)
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("단축어 열기")

            Button("취소") {
                isPresented = false
            }
            .foregroundColor(.red)
            .accessibilityLabel("취소")
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .shadow(radius: 10)
    }
}

import SwiftUI

extension View {
    // 접근성 개선을 위한 커스텀 모디파이어
    func feelinkAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel("FeelinkApp: \(label)")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    // VoiceOver 지원 강화
    func feelinkVoiceOver(announcement: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                VoiceOverService.shared.announce("FeelinkApp: \(announcement)")
            }
        }
    }
    
    // FeelinkApp 공통 스타일링
    func feelinkButtonStyle() -> some View {
        self
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue)
            )
            .padding(.horizontal, 20)
    }
}

import Foundation
import CoreHaptics
import UIKit

class HapticService {
    static let shared = HapticService()
    
    private var hapticEngine: CHHapticEngine?
    
    private init() {
        print("FeelinkApp HapticService 초기화")
        createHapticEngine()
    }
    
    private func createHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("FeelinkApp: 이 기기는 햅틱을 지원하지 않습니다")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("FeelinkApp 햅틱 엔진 시작 성공")
        } catch {
            print("FeelinkApp 햅틱 엔진 생성 실패: \(error)")
        }
        
        // 엔진이 중지되었을 때 자동 재시작
        hapticEngine?.stoppedHandler = { reason in
            print("FeelinkApp 햅틱 엔진이 중지됨: \(reason)")
            do {
                try self.hapticEngine?.start()
                print("FeelinkApp 햅틱 엔진 재시작 성공")
            } catch {
                print("FeelinkApp 햅틱 엔진 재시작 실패: \(error)")
            }
        }
        
        hapticEngine?.resetHandler = {
            print("FeelinkApp 햅틱 엔진 리셋됨")
            do {
                try self.hapticEngine?.start()
            } catch {
                print("FeelinkApp 햅틱 엔진 재시작 실패: \(error)")
            }
        }
    }
    
    // 홀드 제스처 시작 시 햅틱 피드백 (한 번만)
    func triggerLongPressHaptic() {
        print("FeelinkApp 홀드 제스처 햅틱 피드백 실행")
        
        guard let hapticEngine = hapticEngine else {
            print("FeelinkApp Core Haptics 없음, 기본 진동 사용")
            // Core Haptics를 사용할 수 없으면 기본 진동 사용
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            return
        }
        
        // 짧고 강한 햅틱 패턴 - 홀드 시작을 알리는 용도
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("FeelinkApp 햅틱 피드백 성공")
        } catch {
            print("FeelinkApp 햅틱 재생 실패: \(error)")
            // 실패 시 기본 진동으로 대체
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var hasNotificationPermission = false

    private init() {
        print("FeelinkApp NotificationService 초기화")
        checkNotificationPermission()
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
                print("FeelinkApp 알림 권한 상태: \(settings.authorizationStatus)")
            }
        }
    }

    func requestNotificationPermission() {
        print("FeelinkApp 알림 권한 요청")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasNotificationPermission = granted
                if granted {
                    print("FeelinkApp 알림 권한 승인됨")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("FeelinkApp 알림 권한 거부됨")
                }
            }
        }
    }

    // MARK: - 로컬 알림 표시 (챗봇 카테고리 추가)
    /// 로컬 알림을 즉시 표시 - 챗봇 기능 포함
    func showLocalNotification(title: String, body: String, analysisId: String? = nil) {
        print("FeelinkApp 로컬 알림 표시: \(title) - \(body)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // ✅ 챗봇 카테고리 추가
        content.categoryIdentifier = "FEELINK_CHAT"
        
        // iOS 15+ 알림 우선순위 설정
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        // analysisId가 있으면 userInfo에 추가
        if let analysisId = analysisId {
            content.userInfo = ["analysisId": analysisId]
        }

        // 즉시 표시 (1초 후)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("FeelinkApp 로컬 알림 표시 오류: \(error)")
            } else {
                print("FeelinkApp 로컬 알림 표시 성공")
            }
        }
    }

    // MARK: - 백엔드 응답 알림 (챗봇 카테고리 추가)
    /// 백엔드 응답을 알림으로 표시 - 챗봇 기능 포함
    func showBackendResponseNotification(response: String, analysisId: String? = nil) {
        print("FeelinkApp 백엔드 응답 알림: \(response)")
        let content = UNMutableNotificationContent()
        content.title = "FeelinkApp 분석 결과"
        content.body = response
        content.sound = .default
        content.badge = 1
        
        // ✅ 챗봇 카테고리 추가
        content.categoryIdentifier = "FEELINK_CHAT"
        
        // iOS 15+ 알림 우선순위 설정
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        if let analysisId = analysisId {
            content.userInfo = ["analysisId": analysisId]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("FeelinkApp 백엔드 응답 알림 오류: \(error)")
            } else {
                print("FeelinkApp 백엔드 응답 알림 성공")
            }
        }
    }

    // MARK: - 로컬 테스트용 알림 (챗봇 카테고리 추가)
    func sendTestNotification() {
        print("FeelinkApp 테스트 알림 전송")
        let content = UNMutableNotificationContent()
        content.title = "FeelinkApp 분석 완료"
        content.body = "화면에서 테이블과 의자 2개가 발견되었습니다."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["analysisId": "feelink-test-123"]
        
        // ✅ 챗봇 카테고리 추가
        content.categoryIdentifier = "FEELINK_CHAT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("FeelinkApp 로컬 알림 오류: \(error)")
            } else {
                print("FeelinkApp 테스트 알림 전송 완료")
            }
        }
    }

    // MARK: - 알림 배지 제거
    /// 앱 아이콘의 알림 배지를 제거
    func clearNotificationBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    // MARK: - 모든 알림 제거
    /// 대기 중인 모든 알림 제거
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("FeelinkApp 모든 대기 중인 알림 제거 완료")
    }

    // MARK: - 특정 알림 제거
    /// 특정 ID의 알림 제거
    func removePendingNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("FeelinkApp 알림 제거: \(identifier)")
    }
}

// MARK: - 알림 테스트 방법 확장
extension NotificationService {
    /// 다양한 테스트 알림을 보내는 메서드
    func sendVariousTestNotifications() {
        // 1. 기본 테스트 알림
        showLocalNotification(title: "테스트 알림 1", body: "기본 알림 테스트")
        
        // 2. 분석 결과 알림
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showBackendResponseNotification(response: "화면에서 스마트폰과 노트북이 감지되었습니다.", analysisId: "test-analysis-456")
        }
        
        // 3. 긴 텍스트 알림
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.showLocalNotification(
                title: "FeelinkApp 상세 분석",
                body: "화면에서 총 5개의 객체가 감지되었습니다: 테이블 1개, 의자 2개, 컵 1개, 책 1개. 추가 질문이 있으시면 음성으로 물어보세요."
            )
        }
    }
}

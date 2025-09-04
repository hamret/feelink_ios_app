import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // 1. 반드시 텍스트 입력 액션 포함 카테고리 등록
        setupNotificationCategories()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error)")
            } else {
                print("알림 권한 \(granted ? "허용됨" : "거부됨")")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        // 💡 Azure Notification Hub 관련 코드 모두 제거됨

        // 앱이 완전히 꺼진 상태에서 푸시로 실행된 경우
        if let remoteNotification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            if let conversationId = remoteNotification["conversation_id"] as? String {
                NotificationCenter.default.post(name: .showFeelinkAnalysisResult, object: conversationId)
            } else if let analysisId = remoteNotification["analysisId"] as? String {
                NotificationCenter.default.post(name: .showFeelinkAnalysisResult, object: analysisId)
            }
        }

        return true
    }

    // MARK: - Notification Category 등록 (텍스트 입력)
    private func setupNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "FEELINK_REPLY",
            title: "질문하기",
            options: [],
            textInputButtonTitle: "전송",
            textInputPlaceholder: "질문을 입력하세요"
        )
        let chatCategory = UNNotificationCategory(
            identifier: "FEELINK_CHAT",
            actions: [replyAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([chatCategory])
        print("✅ 알림 카테고리 등록 완료: FEELINK_CHAT + 텍스트입력")
    }

    // MARK: - APNs 등록 성공 (register_device로만 처리)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Firebase Messaging에 APNs 토큰 설정 (Analytics 등 Firebase 기능용)
        Messaging.messaging().apnsToken = deviceToken

        // 💡 Azure 관련 코드 모두 제거됨
        // MSNotificationHub 관련 코드 모두 제거

        let installationId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        if let sharedDefaults = UserDefaults(suiteName: "group.com.FeelinkTeam.Feelink") {
            sharedDefaults.set(installationId, forKey: "installationId")
            sharedDefaults.synchronize()
        }

        let tags = ["ios", "feelink_user", "screenshot_app"]
        // APNs 토큰을 hex string으로 변환
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("🔑 APNs 토큰 수신됨: \(tokenString)")
        
        // 💡 오직 register_device 엔드포인트로만 APNs 토큰 등록
        registerDeviceToServer(
            installationId: installationId,
            deviceToken: tokenString,
            platform: "apns", // APNs 플랫폼 명시
            tags: tags
        )
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs 등록 실패:", error.localizedDescription)
    }

    // MARK: - 디바이스 등록 서버 호출 (register_device 엔드포인트) - APNs 자동 등록
    private func registerDeviceToServer(
        installationId: String,
        deviceToken: String,
        platform: String,
        tags: [String]
    ) {
        let urlString = "https://back-feelink-eaaqejgde9bxhabu.koreacentral-01.azurewebsites.net/register_device"
        guard let url = URL(string: urlString) else {
            print("❌ register_device URL 생성 실패")
            return
        }

        // 💡 Form 방식으로 APNs 토큰 전송 (서버에서 자동 등록 처리)
        let tagsString = tags.joined(separator: ",")
        let parameters = [
            "installation_id": installationId,
            "platform": platform, // "apns"로 전송
            "device_token": deviceToken, // APNs 토큰
            "tags": tagsString
        ]
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)

        print("📤 register_device로 APNs 토큰 전송 중...")
        print("   - installation_id: \(installationId)")
        print("   - platform: \(platform)")
        print("   - device_token: \(deviceToken)")
        print("   - tags: \(tagsString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ register_device API 호출 실패:", error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✅ register_device API 응답 코드:", httpResponse.statusCode)
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ register_device API 응답:", responseString)
                    if httpResponse.statusCode == 200 {
                        print("🎉 APNs 디바이스 등록 완료!")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 알림 응답(액션) 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 텍스트 입력 알림 액션 - 질문하기(챗봇) 처리
        if response.actionIdentifier == "FEELINK_REPLY",
           let textResponse = response as? UNTextInputNotificationResponse,
           let conversationIdAny = userInfo["conversation_id"] {

            // 💡 추가된 디버그 print 코드 시작
            print("[DEBUG][Notification] userInfo['conversation_id'] =", conversationIdAny)

            guard let conversationId = conversationIdAny as? String, conversationId.count > 5 else {
                print("[ERROR][Notification] conversation_id가 올바르지 않음: \(conversationIdAny)")
                completionHandler()
                return
            }

            let userInput = textResponse.userText
            print("[DEBUG][Notification] userInput: '\(userInput)', conversation_id: '\(conversationId)'")
            // 💡 추가된 디버그 print 코드 끝

            sendMessageToBackend(message: userInput, conversationId: conversationId)

            // 대화화면 자동 진입
            NotificationCenter.default.post(
                name: .showFeelinkAnalysisResult,
                object: conversationId
            )
        }
        // 새 방식: conversation_id만 있으면 대화화면
        else if let conversationId = userInfo["conversation_id"] as? String {
            print("📌 푸시에서 conversation_id 수신: \(conversationId)")
            NotificationCenter.default.post(
                name: .showFeelinkAnalysisResult,
                object: conversationId
            )
            VoiceOverService.shared.announceAnalysisResult(response.notification.request.content.body)
        }
        // 기존 방식: imageUrl + question + analysisId 조합
        else if let imageUrl = userInfo["imageUrl"] as? String,
                let question = userInfo["question"] as? String,
                let analysisId = userInfo["analysisId"] as? String {
            openScreenshotResultView(
                imageUrl: imageUrl,
                question: question,
                analysisId: analysisId
            )
        }
        // 기존 방식: analysisId만 전달
        else if let analysisId = userInfo["analysisId"] as? String {
            NotificationCenter.default.post(
                name: .showFeelinkAnalysisResult,
                object: analysisId
            )
        }

        completionHandler()
    }

    // 포그라운드 수신 옵션
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - MessagingDelegate (FCM 연동) - FCM 토큰 등록 제거
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("📌 FCM Token 수신됨 (iOS에서는 사용 안함):", token)
        // FCM 토큰 서버 등록 제거 - iOS에서는 APNs 토큰만 사용
        // APIService.shared.registerFCMToken(token) // 제거됨
    }
}

// MARK: - Notification.Name 확장
extension Notification.Name {
    static let showFeelinkAnalysisResult = Notification.Name("showFeelinkAnalysisResult")
}

// MARK: - 서버로 푸시 챗봇 질문 전송 함수 예시(맞게 연결)
func sendMessageToBackend(message: String, conversationId: String) {
    // 💡 추가된 디버그 print 코드 시작
    print("[DEBUG][sendMessageToBackend] conversationId='\(conversationId)' message='\(message)'")
    // 💡 추가된 디버그 print 코드 끝
    
    // 실제 APIService의 챗 메시지 전송 함수로 대체
    APIService.shared.sendChatMessageFromNotification(message, conversationId: conversationId) { result in
        switch result {
        case .success(let response):
            print("[DEBUG][sendMessageToBackend] 서버 응답: \(response.message)") // 💡 추가된 디버그 print
        case .failure(let error):
            print("[DEBUG][sendMessageToBackend] 서버 에러: \(error)") // 💡 추가된 디버그 print
        }
    }
}

// MARK: - (Optional) 분석 결과 화면 바로 열기
private extension AppDelegate {
    func openScreenshotResultView(imageUrl: String, question: String, analysisId: String) {
        DispatchQueue.main.async {
            var screenshotImage: UIImage?
            if let url = URL(string: imageUrl),
               let data = try? Data(contentsOf: url) {
                screenshotImage = UIImage(data: data)
            }
            let analysisResult = AnalysisResult(
                id: analysisId,
                timestamp: Date(),
                summary: "질문: \(question)",
                objects: [],
                text: nil,
                confidence: 1.0,
                screenshotURL: imageUrl,
                appName: "푸시 분석 요청"
            )
            let resultView = ScreenshotResultView(
                analysisResult: analysisResult,
                onDismiss: {
                    if let topVC = self.getTopViewController() {
                        topVC.dismiss(animated: true)
                    }
                }
            )
            let hostingController = UIHostingController(rootView: resultView)
            hostingController.modalPresentationStyle = .fullScreen
            if let topVC = self.getTopViewController() {
                topVC.present(hostingController, animated: true)
            }
        }
    }

    func getTopViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return nil }
        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
struct FeelinkApp_screenshotApp: App {
    @State private var showShortcutPrompt = true
    @StateObject private var notificationService = NotificationService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
                .sheet(isPresented: $showShortcutPrompt) {
                    ShortcutPromptView(isPresented: $showShortcutPrompt)
                }
                .onAppear {
                    notificationService.requestNotificationPermission()
                    VoiceOverService.shared.announce("FeelinkApp 스크린샷 앱이 시작되었습니다.")
                }
        }
    }
}

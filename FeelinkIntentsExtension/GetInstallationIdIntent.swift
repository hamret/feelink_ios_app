import AppIntents

struct GetInstallationIdIntent: AppIntent {
    static var title: LocalizedStringResource = "설치 ID 가져오기"
    static var description = IntentDescription("앱에 저장된 Installation ID를 불러옵니다.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {

        // 앱 그룹 UserDefaults 확인
        if let sharedDefaults = UserDefaults(suiteName: "group.com.FeelinkTeam.Feelink") {
            let installationId = sharedDefaults.string(forKey: "installationId")
            
            // ✅ 콘솔에 값 출력
            print("Installation ID in defaults:", installationId ?? "nil")
            
            if let installationId {
                return .result(value: installationId)
            }
        } else {
            print("UserDefaults for app group not found.")
        }
        
        // 값이 없을 때
        return .result(value: "unknown")
    }
}

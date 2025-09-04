import Foundation

struct PushNotificationPayload: Codable {
    let title: String
    let body: String
    let analysisId: String
    let timestamp: Date
    let appName: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case body
        case analysisId = "analysis_id"
        case timestamp
        case appName = "app_name"
    }
    
    // FeelinkApp용 알림 페이로드 생성
    static func createFeelinkPayload(analysisId: String, summary: String) -> PushNotificationPayload {
        return PushNotificationPayload(
            title: "FeelinkApp 분석 완료",
            body: summary,
            analysisId: analysisId,
            timestamp: Date(),
            appName: "FeelinkApp_screenshot"
        )
    }       
}

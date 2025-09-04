import Foundation

struct AnalysisResult: Codable {
    let id: String
    let timestamp: Date
    let summary: String
    let objects: [DetectedObject]
    let text: String?
    let confidence: Double
    let screenshotURL: String?
    let appName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp 
        case summary
        case objects
        case text
        case confidence
        case screenshotURL = "screenshot_url"
        case appName = "app_name"
    }
    
    // 테스트용 더미 데이터 생성
    static func createTestData() -> AnalysisResult {
        return AnalysisResult(
            id: "feelink-test-\(UUID().uuidString)",
            timestamp: Date(),
            summary: "FeelinkApp 테스트: 화면에서 테이블 1개와 의자 2개, 그리고 컵 1개가 발견되었습니다.",
            objects: [
                DetectedObject(name: "테이블", confidence: 0.95, position: nil),
                DetectedObject(name: "의자", confidence: 0.87, position: nil),
                DetectedObject(name: "컵", confidence: 0.72, position: nil)
            ],
            text: "메뉴판: 아메리카노 4,500원",
            confidence: 0.85,
            screenshotURL: nil, // 실제 구현시 서버에서 제공
            appName: "FeelinkApp_screenshot"
        )
    }
}

struct DetectedObject: Codable {
    let name: String
    let confidence: Double
    let position: BoundingBox?
    
    struct BoundingBox: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
}

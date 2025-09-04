import Foundation

struct ChatResponse: Codable {
    let message: String
    let timestamp: Date?
    let analysisId: String?
    let conversationId: String

    enum CodingKeys: String, CodingKey {
        case message = "answer"
        case timestamp
        case analysisId = "analysis_id"
        case conversationId = "conversation_id"
    }
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError
}

final class APIService {
    static let shared = APIService()
    private let baseURL = "https://back-feelink-eaaqejgde9bxhabu.koreacentral-01.azurewebsites.net"

    private init() {
        print("FeelinkApp APIService 초기화")
    }

    // MARK: - 단축어/스크린샷 분석 → continue_test (푸시 발송) + 서버 응답 String 리턴
    func analyzeScreenshotFromShortcut(
        imageData: Data,
        userQuestion: String = "이 이미지에 대해 자세히 설명해줘",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/continue_test") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // image_file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // user_question
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_question\"\r\n\r\n".data(using: .utf8)!)
        body.append(userQuestion.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    // 예: {"answer":"이 이미지는 ... 입니다."}
                    struct AnalysisResponse: Codable {
                        let answer: String
                    }
                    let decoded = try JSONDecoder().decode(AnalysisResponse.self, from: data)
                    completion(.success(decoded.answer))
                } catch {
                    completion(.failure(APIError.decodingError))
                }
            } else {
                completion(.failure(APIError.serverError))
            }
        }.resume()
    }

    // MARK: - 분석 결과 조회
    func getAnalysisResult(_ analysisId: String, completion: @escaping (Result<AnalysisResult, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/feelink/analysis/\(analysisId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.noData)); return }
            do {
                let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - 알림 텍스트 입력 응답(길게 눌렀을 때)만 /continue_test로 전송
    func sendChatMessageFromNotification(
        _ message: String,
        conversationId: String,
        completion: @escaping (Result<ChatResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/continue_test") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 💡 추가된 디버그 print 코드 시작
        print("[DEBUG][API] 보내는 user_question: '\(message)'")
        print("[DEBUG][API] 보내는 conversation_id: '\(conversationId)'")
        // 💡 추가된 디버그 print 코드 끝

        // user_question
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_question\"\r\n\r\n".data(using: .utf8)!)
        body.append(message.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // conversation_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"conversation_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(conversationId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 💡 추가된 디버그 print 코드 시작
        print("[DEBUG][API] 실제 전송 바디 ↓")
        print(String(data: body, encoding: .utf8) ?? "--body 인코딩 실패--")
        // 💡 추가된 디버그 print 코드 끝

        URLSession.shared.dataTask(with: request) { data, response, error in
            // 💡 추가된 디버그 print 코드 시작
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG][API] 응답 HTTP 상태코드:", httpResponse.statusCode)
            }
            if let data = data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
                print("[DEBUG][API] 응답 바디: \(str)")
            }
            if let error = error {
                print("[DEBUG][API] 네트워크 에러: \(error)")
            }
            // 💡 추가된 디버그 print 코드 끝

            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.noData)); return }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(APIError.decodingError))
                }
            } else {
                completion(.failure(APIError.serverError))
            }
        }.resume()
    }

    // MARK: - 기존 챗봇 메시지는 이제 /test 사용(오직 이 부분만 고침)
    func sendChatMessage(
        _ message: String,
        analysisId: String,
        imageData: Data? = nil,
        completion: @escaping (Result<ChatResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/test") else { // ← 여기만 /test로 수정!
            completion(.failure(APIError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        if let imageData = imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"chat_image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // user_question
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_question\"\r\n\r\n".data(using: .utf8)!)
        body.append(message.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // analysisId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"analysis_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(analysisId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // app name
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"app_name\"\r\n\r\n".data(using: .utf8)!)
        body.append("FeelinkApp_screenshot".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.noData)); return }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(APIError.decodingError))
                }
            } else {
                completion(.failure(APIError.serverError))
            }
        }.resume()
    }

    // MARK: - APNs 토큰 등록 (사용하지 않음 - registerDeviceToServer로 대체됨)
    func registerDeviceToken(_ token: String) {
        // 이 함수는 더 이상 사용하지 않음
        // AppDelegate의 registerDeviceToServer에서 register_device 엔드포인트 사용
        print("[WARNING] registerDeviceToken 함수는 더 이상 사용하지 않습니다. registerDeviceToServer를 사용하세요.")
    }

    // MARK: - FCM 토큰 등록 (iOS에서는 사용하지 않음)
    func registerFCMToken(_ token: String) {
        // iOS에서는 FCM 토큰을 사용하지 않으므로 이 함수는 제거하거나 비활성화
        print("[INFO] iOS에서는 FCM 토큰을 사용하지 않습니다. APNs 토큰만 사용됩니다.")
        // 실제 구현을 주석 처리하거나 제거
        /*
        guard let url = URL(string: "\(baseURL)/feelink/register-fcm-token") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "fcm_token": token,
            "platform": "ios",
            "app_name": "FeelinkApp_screenshot",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
        */
    }
}

 

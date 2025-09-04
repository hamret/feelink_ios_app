import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    // UI 구성요소
    private let questionField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let answerLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    var analysisId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupAccessibility()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 질문 입력 필드
        questionField.placeholder = "추가 질문을 입력하세요 (받아쓰기 지원)"
        questionField.borderStyle = .roundedRect
        questionField.font = UIFont.preferredFont(forTextStyle: .body)
        questionField.adjustsFontForContentSizeCategory = true
        questionField.returnKeyType = .send
        questionField.delegate = self
        questionField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(questionField)
        
        // 전송 버튼
        sendButton.setTitle("질문 보내기", for: .normal)
        sendButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        sendButton.titleLabel?.adjustsFontForContentSizeCategory = true
        sendButton.backgroundColor = UIColor.systemBlue
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        sendButton.addTarget(self, action: #selector(sendQuestion), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        // 응답 표시 라벨
        answerLabel.text = ""
        answerLabel.numberOfLines = 0
        answerLabel.font = UIFont.preferredFont(forTextStyle: .body)
        answerLabel.adjustsFontForContentSizeCategory = true
        answerLabel.textColor = UIColor.label
        answerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(answerLabel)
        
        // 로딩 인디케이터
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 질문 입력 필드
            questionField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            questionField.heightAnchor.constraint(equalToConstant: 44),
            
            // 전송 버튼
            sendButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 12),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 120),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 로딩 인디케이터
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 16),
            
            // 응답 라벨
            answerLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            answerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            answerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            answerLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupAccessibility() {
        questionField.accessibilityLabel = "추가 질문 입력란"
        questionField.accessibilityHint = "받아쓰기를 위해 마이크 버튼을 누르거나 텍스트를 직접 입력하세요"
        
        sendButton.accessibilityLabel = "질문 보내기"
        sendButton.accessibilityHint = "입력한 질문을 서버로 전송합니다"
        
        answerLabel.accessibilityLabel = "AI 응답"
    }
    
    // MARK: - UNNotificationContentExtension
    
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        self.analysisId = userInfo["analysisId"] as? String
        print("📌 Extension에서 analysisId 수신: \(analysisId ?? "nil")")
    }
    
    // MARK: - 서버 통신
    
    @objc private func sendQuestion() {
        guard let question = questionField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !question.isEmpty,
              let analysisId = self.analysisId else {
            showError("질문을 입력해주세요")
            return
        }
        
        // UI 상태 변경
        sendButton.isEnabled = false
        loadingIndicator.startAnimating()
        answerLabel.text = ""
        
        // 서버에 질문 전송
        sendChatRequest(question: question, analysisId: analysisId)
    }
    
    private func sendChatRequest(question: String, analysisId: String) {
        guard let url = URL(string: "https://back-feelink-eaaqejgde9bxhabu.koreacentral-01.azurewebsites.net/start_chat") else {
            showError("서버 URL 오류")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10 // 10초 타임아웃
        
        let params: [String: Any] = [
            "user_question": question,
            "analysis_id": analysisId,
            "app_name": "FeelinkApp_screenshot"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        } catch {
            showError("요청 데이터 생성 실패")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.sendButton.isEnabled = true
                
                if let error = error {
                    self?.showError("네트워크 오류: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.showError("서버 응답 없음")
                    return
                }
                
                // HTTP 상태 코드 확인
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    self?.showError("서버 오류 (코드: \(httpResponse.statusCode))")
                    return
                }
                
                // JSON 응답 파싱
                self?.parseResponse(data)
            }
        }.resume()
    }
    
    private func parseResponse(_ data: Data) {
        do {
            // ChatResponse 구조로 파싱 시도
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["answer"] as? String {
                    showAnswer(message)
                } else if let message = json["message"] as? String {
                    showAnswer(message)
                } else {
                    showError("응답 형식 오류")
                }
            } else {
                showError("JSON 파싱 실패")
            }
        } catch {
            showError("응답 해석 실패: \(error.localizedDescription)")
        }
    }
    
    private func showAnswer(_ answer: String) {
        answerLabel.text = answer
        questionField.text = "" // 입력 필드 초기화
        
        // VoiceOver 사용자를 위한 접근성 알림
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: "AI 응답: \(answer)")
        }
    }
    
    private func showError(_ message: String) {
        answerLabel.text = "❌ \(message)"
        answerLabel.textColor = .systemRed
        
        // 일정 시간 후 색상 복원
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.answerLabel.textColor = UIColor.label
        }
        
        // VoiceOver 사용자를 위한 접근성 알림
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: "오류: \(message)")
        }
    }
}

// MARK: - UITextFieldDelegate

extension NotificationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendQuestion()
        return true
    }
}
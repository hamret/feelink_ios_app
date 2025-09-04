import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: ObservableObject {
    
    // ✅ 누락된 프로퍼티 추가
    @Published var recognizedText: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var completion: ((Result<String, Error>) -> Void)?
    private var silenceTimer: Timer?
    
    init() {
        print("FeelinkApp SpeechRecognitionService 초기화")
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("FeelinkApp 음성 인식 권한 승인됨")
                case .denied, .restricted, .notDetermined:
                    print("FeelinkApp 음성 인식 권한 거부됨")
                @unknown default:
                    break
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("FeelinkApp 마이크 권한 승인됨")
            } else {
                print("FeelinkApp 마이크 권한 거부됨")
            }
        }
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        print("🎙️ FeelinkApp 음성 녹음 시작")
        self.completion = completion
        
        // ✅ 인식 텍스트 초기화
        DispatchQueue.main.async {
            self.recognizedText = ""
        }
        
        // 기존 작업 정리
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("FeelinkApp 오디오 세션 설정 실패: \(error)")
            completion(.failure(error))
            return
        }
        
        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("FeelinkApp 인식 요청 생성 실패")
            completion(.failure(SpeechError.recognitionRequestCreationFailed))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 음성 인식 작업 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let newText = result.bestTranscription.formattedString
                
                // ✅ UI 업데이트는 메인 스레드에서
                DispatchQueue.main.async {
                    self.recognizedText = newText
                }
                
                print("FeelinkApp 인식 중: \(newText)")
                
                // 말이 끝났는지 감지 (1.5초 침묵)
                self.silenceTimer?.invalidate()
                self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    print("FeelinkApp 침묵 감지, 인식 종료")
                    self.stopRecording()
                    if self.completion != nil {
                        self.completion?(.success(self.recognizedText))
                        self.completion = nil
                    }
                }
                
                if result.isFinal {
                    print("FeelinkApp 인식 최종 완료")
                    self.silenceTimer?.invalidate()
                    self.stopRecording()
                    if self.completion != nil {
                        self.completion?(.success(self.recognizedText))
                        self.completion = nil
                    }
                }
            }
            
            if let error = error {
                print("FeelinkApp 음성 인식 오류: \(error)")
                if self.completion != nil {
                    self.stopRecording()
                    self.completion?(.failure(error))
                    self.completion = nil
                }
            }
        }
        
        // 오디오 입력 설정
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("FeelinkApp 오디오 엔진 시작")
        } catch {
            print("FeelinkApp 오디오 엔진 시작 실패: \(error)")
            completion(.failure(error))
        }
    }
    
    func stopRecording() {
        print("FeelinkApp 음성 녹음 중단")
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 오디오 세션 비활성화
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("FeelinkApp 오디오 세션 비활성화")
        } catch {
            print("FeelinkApp 오디오 세션 비활성화 실패: \(error)")
        }
    }
}

enum SpeechError: Error {
    case recognitionRequestCreationFailed
    case noSpeechRecognizer
    
    var localizedDescription: String {
        switch self {
        case .recognitionRequestCreationFailed:
            return "FeelinkApp: 음성 인식 요청 생성 실패"
        case .noSpeechRecognizer:
            return "FeelinkApp: 음성 인식기가 없습니다"
        }
    }
}

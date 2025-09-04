import SwiftUI
import PhotosUI

struct ScreenshotResultView: View {
    var analysisResult: AnalysisResult?
    var onDismiss: () -> Void // 화면을 닫기 위한 콜백
    
    @State private var localAnalysisResult: AnalysisResult?
    @State private var isLoading = true
    @State private var screenshotImage: UIImage?
    
    private let primaryColor = Color(red: 126/255, green: 200/255, blue: 255/255)
    @State private var permissionGranted = false
    @State private var chatbotResponse: String = ""

    private var displayResult: AnalysisResult? {
        analysisResult ?? localAnalysisResult
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if let result = displayResult {
                mainContentView(with: result)
            } else if isLoading {
                ProgressView("최근 스크린샷을 분석 중입니다...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            }
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: permissionGranted) { granted in
            if granted {
                fetchLatestScreenshotAndAnalyze()
            }
        }
    }

    // MARK: - Subviews

    private func mainContentView(with result: AnalysisResult) -> some View {
        VStack {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(primaryColor, lineWidth: 3)
                    )
                
                VStack(spacing: 15) {
                    if let screenshotImage = screenshotImage {
                        Image(uiImage: screenshotImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    } else {
                        // Fallback if image is not available
                        Image(systemName: "photo.fill") // A generic photo icon
                            .font(.system(size: 50)).foregroundColor(.gray)
                    }
                    
                    Text(result.appName ?? "분석 결과")
                        .font(.title2).foregroundColor(.black)
                    
                    Text(result.summary)
                        .font(.body).foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    // Display chatbot response here
                    if !chatbotResponse.isEmpty {
                        Text(chatbotResponse)
                            .font(.body).foregroundColor(.blue) // Use a distinct color
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .overlay(VoiceChatView(analysisResult: result, screenshotImage: screenshotImage, chatResponse: $chatbotResponse)) // 오버레이를 ZStack으로 이동
            
            Spacer()
            
            // 버튼 수정
            Button(action: {
                onDismiss() // 상위 뷰에 정의된 닫기 액션 호출
            }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("메인화면으로 돌아가기") // 텍스트 변경
                }
                .font(.title2.weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(RoundedRectangle(cornerRadius: 8).fill(primaryColor))
                .padding([.horizontal, .bottom], 20)
            }
            .accessibilityLabel("메인 화면으로 돌아가기")
        }
        .onAppear {
            var announcementText = "분석 결과 화면입니다. \(result.summary)."
            if !chatbotResponse.isEmpty {
                announcementText += " 챗봇 응답: \(chatbotResponse)."
            }
            announcementText += " 화면을 길게 누르면 음성으로 질문할 수 있습니다."
            VoiceOverService.shared.announce(announcementText)
        }
    }

    // MARK: - Logic

    private func handleOnAppear() {
        if analysisResult != nil {
            isLoading = false
            return
        }
        checkPhotoLibraryPermission()
    }

    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            permissionGranted = true
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.permissionGranted = (newStatus == .authorized || newStatus == .limited)
                    if !self.permissionGranted {
                        // 권한 거부 시에도 일단 분석 시도 (로직상 1분 내 사진 없음으로 귀결됨)
                        fetchLatestScreenshotAndAnalyze()
                    }
                }
            }
        } else {
            // 권한이 이미 거부된 상태
            fetchLatestScreenshotAndAnalyze()
        }
    }

    private func fetchLatestScreenshotAndAnalyze() {
        // 권한이 없으면 바로 오류 표시
        guard permissionGranted else {
            showErrorResult(message: "사진 보관함 접근 권한이 없어 스크린샷을 찾을 수 없습니다. 설정에서 권한을 허용해주세요.")
            return
        }

        let fetchOptions = PHFetchOptions()
        // 1. 시간 조건 추가: 최근 1분
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@", oneMinuteAgo as NSDate)
        // 2. 정렬 조건 유지
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if #available(iOS 14, *) {
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
            guard let screenshotsAlbum = smartAlbums.firstObject else {
                showErrorResult(message: "스크린샷 앨범을 찾을 수 없습니다.")
                return
            }
            let fetchResult = PHAsset.fetchAssets(in: screenshotsAlbum, options: fetchOptions)
            guard let latestScreenshotAsset = fetchResult.firstObject else {
                // 3. 오류 메시지 변경
                showErrorResult(message: "최근 1분 내에 촬영된 스크린샷이 없습니다.")
                return
            }
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImage(for: latestScreenshotAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                guard let image = image, let imageData = image.jpegData(compressionQuality: 0.8) else {
                    showErrorResult(message: "이미지를 데이터로 변환하는데 실패했습니다.")
                    return
                }
                self.screenshotImage = image
                
                APIService.shared.analyzeScreenshotFromShortcut(imageData: imageData) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let summary):
                            self.localAnalysisResult = AnalysisResult(
                                id: "guest-\(UUID().uuidString)", timestamp: Date(), summary: summary, objects: [], text: nil, confidence: 0.9, screenshotURL: nil, appName: "최근 스크린샷 분석"
                            )
                        case .failure(let error):
                            showErrorResult(message: "이미지 분석에 실패했습니다: \(error.localizedDescription)")
                        }
                        self.isLoading = false
                    }
                }
            }
        } else {
            showErrorResult(message: "이 기능은 iOS 14 이상에서만 지원됩니다.")
        }
    }
    
    private func showErrorResult(message: String) {
        self.localAnalysisResult = AnalysisResult(
            id: "error-\(UUID().uuidString)", timestamp: Date(), summary: message, objects: [], text: nil, confidence: 0, screenshotURL: nil, appName: "오류"
        )
        self.isLoading = false
    }
}

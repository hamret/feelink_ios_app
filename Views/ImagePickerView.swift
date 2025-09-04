import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("갤러리에서 이미지 선택")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .accessibilityLabel("갤러리에서 이미지 선택")
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
                
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                    
                    if isLoading {
                        ProgressView("업로드 중...")
                    } else {
                        Button("이 이미지로 분석하기") {
                            uploadImage(selectedImage)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("이 이미지로 분석하기")
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("갤러리 분석")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                    .accessibilityLabel("닫기")
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isLoading = true
        APIService.shared.analyzeScreenshotFromShortcut(imageData: data, userQuestion: "이 이미지에 대해 자세히 설명해줘") { result in
            DispatchQueue.main.async {
                isLoading = false
                dismiss()
                switch result {
                case .success:
                    NotificationService.shared.showLocalNotification(
                        title: "갤러리 이미지 분석 완료",
                        body: "서버가 이미지를 정상 처리했습니다."
                    )
                    print("이미지 업로드 성공. 서버가 알림을 보낼 것입니다.")
                case .failure(let error):
                    NotificationService.shared.showLocalNotification(
                        title: "갤러리 이미지 분석 실패",
                        body: "오류: \(error.localizedDescription)"
                    )
                    print("이미지 업로드 실패: \(error)")
                }
            }
        }
    }

}

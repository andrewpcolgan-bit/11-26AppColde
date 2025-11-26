import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    let onImage: (UIImage) -> Void
    
    var body: some View {
        CameraPicker(onImage: { image in
            onImage(image)
            dismiss()
        })
        .ignoresSafeArea()
    }
}

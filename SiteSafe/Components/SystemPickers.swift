//
//  SystemPickers.swift
//  SiteSafe
//
//  UIKit bridges that SwiftUI lacks on iOS 14: camera + library pickers, the
//  share sheet (PDF / backup export), a blur view, and a finger signature pad.
//

import SwiftUI
import PhotosUI

// MARK: - Camera

struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.presentationMode.wrappedValue.dismiss()
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Photo library (PHPicker)

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async { self.parent.onPick(image) }
                }
            }
        }
    }
}

// MARK: - Image source picker (sheet item)

enum ImageSource: Identifiable {
    case camera, library
    var id: Int { self == .camera ? 0 : 1 }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = UIApplication.shared.windows.first
            pop.sourceRect = CGRect(x: UIScreen.main.bounds.midX,
                                    y: UIScreen.main.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Blur

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemThinMaterialDark
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Signature pad

struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]
    @Binding var canvasSize: CGSize
    @State private var current: [CGPoint] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft)
                RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1)

                // Committed strokes
                ForEach(Array(strokes.enumerated()), id: \.offset) { _, stroke in
                    SignatureLine(points: stroke)
                        .stroke(Theme.primary, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                }
                // In-progress stroke
                SignatureLine(points: current)
                    .stroke(Theme.primary, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

                if strokes.isEmpty && current.isEmpty {
                    Text("Sign here")
                        .font(Theme.caption(13))
                        .foregroundColor(Theme.textDisabled)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in current.append(v.location) }
                    .onEnded { _ in
                        if !current.isEmpty { strokes.append(current); current = [] }
                    }
            )
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { canvasSize = $0 }
        }
        .frame(height: 150)
    }
}

private struct SignatureLine: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }
}

/// Renders captured signature strokes into a JPEG-able UIImage.
func renderSignatureImage(strokes: [[CGPoint]], size: CGSize) -> UIImage? {
    guard size.width > 0, size.height > 0, !strokes.isEmpty else { return nil }
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        UIColor(hex: 0x1E1C12).setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.cgContext.setStrokeColor(UIColor(hex: 0xFACC15).cgColor)
        ctx.cgContext.setLineWidth(2.6)
        ctx.cgContext.setLineCap(.round)
        ctx.cgContext.setLineJoin(.round)
        for stroke in strokes {
            guard let first = stroke.first else { continue }
            ctx.cgContext.move(to: first)
            for p in stroke.dropFirst() { ctx.cgContext.addLine(to: p) }
            ctx.cgContext.strokePath()
        }
    }
}

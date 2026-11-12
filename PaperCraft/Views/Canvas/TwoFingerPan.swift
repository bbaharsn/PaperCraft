//
//  TwoFingerPan.swift
//  PaperCraft
//

#if os(iOS)
import SwiftUI
import UIKit

/// İki parmakla sürüklemeyi dinler (iOS 17'de SwiftUI'da hazır karşılığı yok).
/// Arka plan olarak eklenir; dokunuşları engellemez, yalnızca bu görünümün alanında başlayan
/// iki parmaklı hareketi yakalar. Diğer hareketlerle (ör. iki parmakla yakınlaştırma) aynı anda çalışır.
struct TwoFingerPan: UIViewRepresentable {
    /// Hareketin başından beri kat edilen yol (ekran point'i).
    var onChanged: (CGSize) -> Void
    var onEnded: () -> Void

    func makeUIView(context: Context) -> MarkerView {
        let view = MarkerView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MarkerView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    /// Alanı belirleyen görünmez görünüm. Hareket tanıyıcıyı, bulunduğu ekranın kök görünümüne takar;
    /// böylece açılan sayfalardaki (sheet) dokunuşlar canvas'ı kaydırmaz.
    final class MarkerView: UIView {
        weak var coordinator: Coordinator?
        private weak var host: UIView?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let coordinator else { return }
            if let host { host.removeGestureRecognizer(coordinator.recognizer) }
            host = nil
            guard window != nil else { return }
            var root: UIView = self
            while let parent = root.superview, !(root.next is UIViewController) { root = parent }
            root.addGestureRecognizer(coordinator.recognizer)
            coordinator.marker = self
            host = root
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: TwoFingerPan
        weak var marker: UIView?
        lazy var recognizer: UIPanGestureRecognizer = {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            pan.cancelsTouchesInView = false
            pan.delegate = self
            return pan
        }()

        init(parent: TwoFingerPan) { self.parent = parent }

        @objc private func handle(_ pan: UIPanGestureRecognizer) {
            switch pan.state {
            case .began, .changed:
                let t = pan.translation(in: nil)
                parent.onChanged(CGSize(width: t.x, height: t.y))
            case .ended, .cancelled, .failed:
                parent.onEnded()
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let marker else { return false }
            return marker.bounds.contains(gestureRecognizer.location(in: marker))
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
#endif

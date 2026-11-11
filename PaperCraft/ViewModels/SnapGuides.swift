//
//  SnapGuides.swift
//  PaperCraft
//

import CoreGraphics

/// Taşınan elemanın hizaya yapışmasını hesaplar. Arayüzden bağımsızdır; her şey referans ekranın point'iyle.
///
/// Her karede parmağın getirdiği **ham** konumdan yeniden hesaplanır. Böylece eleman eşiğin
/// dışına çekilince kendiliğinden kurtulur.
/// İki hiza var, ikisi de dikey çizgi: elemanın ortası sayfanın ortasında, ya da sol kenarı başka bir
/// elemanın sol kenarında. Ekran çizgiyle dolmasın diye bilerek bu kadar.
/// Tasarım: `docs/superpowers/specs/2026-11-11-snap-guides-design.md`.
nonisolated enum SnapGuides {
    /// Yapışma mesafesi, ekran point'iyle. Yakınlaştırılmışken tuvalde `threshold / scale` olur.
    static let threshold: CGFloat = 6

    /// - Parameters:
    ///   - rect: taşınan elemanın ham dikdörtgeni.
    ///   - targets: sol kenarına hizalanılabilecek diğer elemanlar.
    ///   - tolerance: tuval point'iyle eşik.
    static func snapMove(_ rect: CGRect, targets: [CGRect] = [],
                         pageWidth: CGFloat, tolerance: CGFloat) -> SnapResult {
        let center = pageWidth / 2
        var candidates: [(distance: CGFloat, match: Match)] = [
            (center - rect.midX, Match(position: center, target: nil)),
        ]
        for target in targets {
            // Ekranın sol kenarına dayalı eleman (tam genişlikteki üst bar gibi) hedef değil.
            guard target.minX > 0.5 else { continue }
            candidates.append((target.minX - rect.minX, Match(position: target.minX, target: target)))
        }

        let inRange = candidates.filter { abs($0.distance) <= tolerance }
        guard let best = inRange.min(by: { abs($0.distance) < abs($1.distance) }) else { return SnapResult() }

        // Çizgi, yapışılmış konumdaki elemanla hizalanan elemanları birlikte kapsar; sayfa ortası kart boyunca.
        let snapped = rect.offsetBy(dx: best.distance, dy: 0)
        let span = best.match.target.map { target in
            inRange.filter { abs($0.distance - best.distance) < 0.01 }
                .compactMap(\.match.target)
                .reduce(min(snapped.minY, target.minY)...max(snapped.maxY, target.maxY)) { span, other in
                    min(span.lowerBound, other.minY)...max(span.upperBound, other.maxY)
                }
        }
        return SnapResult(offset: CGSize(width: best.distance, height: 0),
                          guides: [SnapGuide(axis: .vertical, position: best.match.position, span: span)])
    }

    /// Döndürülmüş elemanın ekranda kapladığı kutu; merkez aynı kalır.
    static func boundingBox(_ rect: CGRect, degrees: Double) -> CGRect {
        guard degrees.truncatingRemainder(dividingBy: 360) != 0 else { return rect }
        let angle = degrees * .pi / 180
        let c = abs(cos(angle)), s = abs(sin(angle))
        let width = rect.width * c + rect.height * s
        let height = rect.width * s + rect.height * c
        return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
    }

    /// Bir hiza: çizginin konumu ve hizalanan eleman (sayfa ortasında `nil`).
    private struct Match {
        var position: CGFloat
        var target: CGRect?
    }
}

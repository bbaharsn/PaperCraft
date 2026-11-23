//
//  EditorViewModel+TextFit.swift
//  PaperCraft
//

import CoreGraphics

extension EditorViewModel {
    /// Metnin, yazısına oturan kutusu (point). Yazının şu an çizildiği yerde durur.
    func fittedTextRect(of element: CanvasElement) -> CGRect {
        let size = TextMeasure.size(of: element.properties, maxWidth: canvasSize.width)
        return TextFit.rect(for: size, in: pointRect(of: element),
                            alignment: element.properties.textAlignment ?? .leading,
                            canvasWidth: canvasSize.width)
    }

    /// Metin köşeden çekilince kutu yazıya oturur ve kutuyla yazı birlikte, oranı korunarak büyür;
    /// hangi yöne daha çok çekildiyse o kadar. Çekilen köşenin karşısı yerinde kalır, sayfanın yanlarından
    /// ve üstünden taşmaz. Yazı en az 6 pt olur.
    func resizeTextProportionally(at index: Int, from corner: ResizeCorner, start: ElementResizeStart) {
        var startElement = screen.elements[index]
        startElement.frame = normalizedFrame(for: start.rect)
        startElement.properties.contentScale = start.contentScale
        let fitted = fittedTextRect(of: startElement)
        guard fitted.width > 0, fitted.height > 0 else { return }

        let startFontSize = TextMeasure.fontSize(of: startElement.properties)
        let minimumScale = min(1, 6 / startFontSize)
        let scale = GroupResize.scale(dragging: corner, by: start.translation, rect: fitted,
                                      canvasWidth: canvasSize.width, minimumScale: minimumScale)

        var element = startElement
        element.properties.contentScale = start.contentScale
        if abs(scale - 1) > 0.0001 {
            element.properties.scaleContent(by: scale)
        }
        // Yeni boyut yeniden ölçülür (yazı tam orantılı büyümeyebilir); karşı köşe yerinde kalır.
        let size = TextMeasure.size(of: element.properties, maxWidth: canvasSize.width)
        let anchor = GroupResize.anchor(of: corner, in: fitted)
        let x = corner.isLeading ? anchor.x - size.width : anchor.x
        let y = corner.isTop ? anchor.y - size.height : anchor.y
        let rect = CGRect(x: min(max(x, 0), max(canvasSize.width - size.width, 0)), y: max(y, 0),
                          width: size.width, height: size.height)
        element.frame = normalizedFrame(for: rect)
        screen.elements[index] = element
    }
}

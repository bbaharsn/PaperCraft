//
//  MockScreens.swift
//  PaperCraft
//

import Foundation

/// Geliştirme ve önizleme için hazır örnek ekranlar.
/// Gerçek kullanıcı verisi değildir; tasarım ve AI hazır olunca kaldırılabilir.
enum MockScreens {

    /// Örnek bir "Giriş Ekranı" üretir. Elemanlar katalogdaki varsayılanlardan türetilir.
    static func login(using catalog: ComponentCatalog) -> PrototypeScreen {
        var navigationBar = catalog.makeElement(of: .navigationBar)
        navigationBar?.properties.text = "Giriş"

        var title = catalog.makeElement(of: .text)
        title?.properties.text = "Hoş geldin"
        title?.properties.textStyle = .largeTitle
        title?.properties.fontWeight = .bold
        title?.frame.y = 0.12
        title?.frame.height = 0.05

        var email = catalog.makeElement(of: .textField)
        email?.properties.placeholder = "E-posta"
        email?.frame.y = 0.25

        var password = catalog.makeElement(of: .textField)
        password?.properties.placeholder = "Şifre"
        password?.properties.inputKind = .secure
        password?.frame.y = 0.32

        var rememberMe = catalog.makeElement(of: .switch)
        rememberMe?.properties.text = "Beni hatırla"
        rememberMe?.properties.isOn = false
        rememberMe?.frame.y = 0.40

        var loginButton = catalog.makeElement(of: .button)
        loginButton?.properties.text = "Giriş Yap"
        loginButton?.frame.y = 0.50

        // Katalogda bulunamayan (nil) elemanlar listeden atılır.
        let elements = [navigationBar, title, email, password, rememberMe, loginButton]
            .compactMap { $0 }

        return PrototypeScreen(name: "Giriş Ekranı", elements: elements)
    }
}

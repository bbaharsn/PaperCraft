//
//  ThemeTests.swift
//  PaperCraftTests
//

import Testing
import UIKit
@testable import PaperCraft

@MainActor
struct ThemeTests {

    @Test func bundleContainsAtLeastOneFont() {
        let fontCount = FontRegistrar.registerBundledFonts()
        #expect(fontCount >= 1)
    }

    @Test func logoFontIsAvailableAfterRegistration() {
        FontRegistrar.registerBundledFonts()
        let font = UIFont(name: Theme.logoFontName, size: 24)
        #expect(font != nil, "Logo fontu bulunamadı: \(Theme.logoFontName)")
    }
}

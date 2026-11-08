//
//  LicenseTests.swift
//  PaperCraftTests
//

import Testing
@testable import PaperCraft

struct LicenseTests {

    /// Her lisansın metni uygulamanın içinde olmalı; yoksa Lisanslar ekranı boş kalır.
    @Test(arguments: License.all)
    func licenseTextIsBundled(_ license: License) throws {
        let text = try #require(license.text())
        #expect(text.count > 500)
    }

    @Test func licenseFileNamesAreUnique() {
        let names = License.all.map(\.fileName)
        #expect(Set(names).count == names.count)
    }
}

//
//  PanelNavigatorTests.swift
//  PaperCraftTests
//

import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct PanelNavigatorTests {

    private func page(_ title: String) -> PanelPage {
        PanelPage(title: title, content: AnyView(EmptyView()))
    }

    @Test func startsOnMainContent() {
        let navigator = PanelNavigator()
        #expect(navigator.pages.isEmpty)
        #expect(navigator.top == nil)
    }

    @Test func pushShowsNewestPage() {
        let navigator = PanelNavigator()
        navigator.push(page("Yazı Tipi"))
        navigator.push(page("Sekme 2"))
        #expect(navigator.top?.title == "Sekme 2")
        #expect(navigator.pages.count == 2)
    }

    @Test func popReturnsToPreviousPage() {
        let navigator = PanelNavigator()
        navigator.push(page("Sekme 1"))
        navigator.pop()
        #expect(navigator.top == nil)
    }

    @Test func popOnMainContentDoesNothing() {
        let navigator = PanelNavigator()
        navigator.pop()
        #expect(navigator.pages.isEmpty)
    }
}

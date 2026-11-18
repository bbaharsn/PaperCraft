//
//  NewProjectLabelStyle.swift
//  PaperCraft
//

import SwiftUI

/// "Yeni proje" düğmesinin etiketi: geniş yerde ikon + yazı, iPad kenar listesinde yalnızca ikon.
struct NewProjectLabelStyle: LabelStyle {
    let compact: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if compact {
            configuration.icon
        } else {
            HStack(spacing: 6) {
                configuration.icon
                configuration.title
            }
        }
    }
}

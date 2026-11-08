//
//  LicenseDetailView.swift
//  PaperCraft
//

import SwiftUI

/// Bir lisansın tam metni.
struct LicenseDetailView: View {
    let license: License

    var body: some View {
        ScrollView {
            Text(license.text() ?? "Lisans metni bulunamadı.")
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(license.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        LicenseDetailView(license: License.all[0])
    }
}

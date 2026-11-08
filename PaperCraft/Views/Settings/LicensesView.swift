//
//  LicensesView.swift
//  PaperCraft
//

import SwiftUI

/// Projelerim'deki ⓘ ile açılan "Lisanslar" sayfası: kullanılan açık kaynak parçaların listesi.
struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(License.all) { license in
                NavigationLink(value: license) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(license.name)
                            .font(.system(size: 16, weight: .semibold))
                        Text(license.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Lisanslar")
            .navigationDestination(for: License.self) { LicenseDetailView(license: $0) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LicensesView()
}

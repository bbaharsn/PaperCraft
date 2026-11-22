//
//  EditorViewModel+MultiEdit.swift
//  PaperCraft
//

import Foundation

/// Toplu seçimde aynı türdeki elemanların Özellikler'ini birlikte düzenleme.
/// Sayfa ilk elemanın değerlerini gösterir (`selectedElementID` ona ayarlanır); yapılan her değişiklik
/// `propertyTargetIDs`'deki bütün elemanlara uygulanır.
extension EditorViewModel {
    /// Toplu seçimdeki elemanların ortak türü; seçim boşsa ya da türler karışıksa `nil`.
    var multiSelectionEditType: ElementType? {
        guard isMultiSelecting else { return nil }
        let types = Set(screen.elements.filter { multiSelection.contains($0.id) }.map(\.type))
        return types.count == 1 ? types.first : nil
    }

    /// Toplu seçimin Özellikler'ini açar: değerleri okunacak ilk eleman seçilir, toplu mod açık kalır.
    func openMultiSelectionProperties() {
        guard multiSelectionEditType != nil else { return }
        selectedElementID = screen.elements.first { multiSelection.contains($0.id) }?.id
    }

    /// Özellikler açıkken toplu seçim değişirse: türler karışınca ya da seçim boşalınca sayfa kapanır
    /// (`selectedElementID` nil), yoksa değerler yine seçimin ilk elemanından okunur.
    func refreshMultiSelectionProperties() {
        guard isMultiSelecting, selectedElementID != nil else { return }
        selectedElementID = multiSelectionEditType == nil
            ? nil : screen.elements.first { multiSelection.contains($0.id) }?.id
    }

    /// Toplu seçimin Özellikler'i kapanınca seçim yine yalnızca toplu seçimdir.
    func closeMultiSelectionProperties() {
        guard isMultiSelecting else { return }
        selectedElementID = nil
    }

    /// Özellik değişikliğinin uygulanacağı elemanlar: tek seçimde seçili eleman; toplu seçimin
    /// Özellikler'i açıkken seçimdeki aynı türden bütün elemanlar.
    var propertyTargetIDs: Set<UUID> {
        guard let selected = selectedElement else { return [] }
        guard isMultiSelecting, multiSelection.contains(selected.id) else { return [selected.id] }
        return Set(screen.elements.filter { multiSelection.contains($0.id) && $0.type == selected.type }.map(\.id))
    }
}

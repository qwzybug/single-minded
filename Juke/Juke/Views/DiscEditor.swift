//
//  DiscForm.swift
//  Juke
//
//  Created by devin chalmers on 2/5/23.
//

import SwiftUI

struct DiscEditor: View {
    enum Error: LocalizedError {
        case validationError(NSError)
        case unexpectedError

        var errorDescription: String? {
            switch self {
            case .unexpectedError: return "Unexpected error"
            case .validationError(let error): return error.localizedDescription
            }
        }
        var recoverySuggestion: String? {
            switch self {
            case .unexpectedError: return nil
            case .validationError(let error): return error.localizedRecoverySuggestion
            }
        }

    }

    @Environment(\.dismiss) var dismiss

    @ObservedObject var disc: Disc

    @State var sideAArtistName: String
    @State var sideBArtistName: String
    @State var sideBHasDifferentArtist: Bool

    @State var error: Error?

    init(disc editingDisc: Disc) {
        self.disc = editingDisc
        _sideAArtistName = State(initialValue: editingDisc.sideAArtist?.name ?? "")
        _sideBArtistName = State(initialValue: editingDisc.sideBArtist?.name ?? "")
        _sideBHasDifferentArtist = State(initialValue: editingDisc.sideAArtist != editingDisc.sideBArtist)
    }

    var body: some View {
        Form {
            TextField(sideBHasDifferentArtist ? "Side A Artist" : "Artist", text: $sideAArtistName)

            TextField("Side A", text: Binding($disc.sideATitle)!)
            TextField("Side B", text: Binding($disc.sideBTitle)!)

            Toggle(isOn: $sideBHasDifferentArtist) {
                Text("Different artist on Side B")
            }

            TextField("Side B Artist", text: sideBHasDifferentArtist ? $sideBArtistName : $sideAArtistName)
                .disabled(!sideBHasDifferentArtist)

            Button("Cancel") {
                dismiss()
            }

            Button("Save", action: saveAction).keyboardShortcut(.return)
        }
        .onSubmit(saveAction)
        .padding(16)
        .alert(isPresented: .constant(error != nil), error: error) { _ in
            Button("OK") {
                $error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }

    func saveAction() {
        guard let context = disc.managedObjectContext else {
            error = Error.unexpectedError
            return
        }

        do {
            disc.sideAArtist = try Artist.named(sideAArtistName, in: context)
            if sideBHasDifferentArtist {
                disc.sideBArtist = try Artist.named(sideBArtistName, in: context)
            } else {
                disc.sideBArtist = disc.sideAArtist
            }
            disc.createdAt = Date()

            try context.save()

            dismiss()
        } catch {
            if let nsError = error as? NSError, let detailedErrors = nsError.userInfo["NSDetailedErrors"] as? [NSError], let firstError = detailedErrors.first {
                self.error = .validationError(firstError)
            } else {
                self.error = .unexpectedError
            }
        }
    }
}

struct DiscForm_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.preview.container.viewContext
        let mocks = Disc.mocks
        let disc = mocks.first!
        DiscEditor(disc: disc)
    }
}

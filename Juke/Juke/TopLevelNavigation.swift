//
//  TopLevelNavigation.swift
//  Juke
//
//  Created by devin chalmers on 2/6/23.
//

import SwiftUI

enum DetailMode: String, Identifiable, CaseIterable {
    var id: Self { self }
    case library
    case jukebox
    case test
}

struct TopLevelNavigation: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var mode = DetailMode.library

    var body: some View {
        NavigationSplitView {
            List(DetailMode.allCases, selection: $mode) { mode in
                Text(mode.rawValue.capitalized)
            }
        } detail: {
            switch mode {
            case .library:
                LibraryView().environment(\.managedObjectContext, viewContext)

            case .jukebox:
                let program = JukeboxProgram()
                ScrollView([.horizontal, .vertical]) {
                    JukeboxPanel(layout: JukeboxLayout.seeburgM100)
                }

            case .test:
                testView
            }
        }
    }

    var testView: some View {
        GeometryReader { geometry in
            Text("\(geometry.size.width) x \(geometry.size.height)")
        }
    }
}

struct TopLevelNavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopLevelNavigation()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

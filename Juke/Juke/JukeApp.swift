//
//  JukeApp.swift
//  Juke
//
//  Created by devin chalmers on 2/4/23.
//

import SwiftUI

@main
struct JukeApp: App {
    let persistenceController = PersistenceController.preview

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }

        Window("Jukebox", id: "jukebox") {
            JukeboxPanel(layout: JukeboxType.seeburgM100.layout)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

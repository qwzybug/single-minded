//
//  MockData.swift
//  Juke
//
//  Created by devin chalmers on 2/7/23.
//

import CoreData
import CoreGraphics
import Foundation

extension Disc {
    static var _mocks: [Disc]!

    static func create(sideAArtistName: String, sideATitle: String, sideBArtistName: String, sideBTitle: String, in context: NSManagedObjectContext) throws -> Disc {
        let disc = Disc(context: context)
        disc.sideAArtist = try Artist.named(sideAArtistName, in: context)
        disc.sideBArtist = try Artist.named(sideBArtistName, in: context)
        disc.sideATitle = sideATitle
        disc.sideBTitle = sideBTitle
        disc.createdAt = Date()
        return disc
    }

    static var mocks: [Disc] {
        if _mocks == nil { createMocks(in: PersistenceController.preview.container.viewContext) }
        return _mocks!
    }

    static func createMocks(in context: NSManagedObjectContext) {
        if _mocks != nil { return }

        let mockData: [(sideAArtist: String, sideATitle: String, sideBArtist: String, sideBTitle: String)] = [
            (sideAArtist: "Louis Armstrong", sideATitle: "Mack the Knife", sideBArtist: "Louis Armstrong", sideBTitle: "St. Louis Blues"),
            (sideAArtist: "Louis Armstrong", sideATitle: "April in Paris", sideBArtist: "Louis Armstrong", sideBTitle: "What A Wonderful World"),
            (sideAArtist: "Beach Boys", sideATitle: "Help Me Rhonda", sideBArtist: "Beach Boys", sideBTitle: "California Girls"),
            (sideAArtist: "King Tubbys", sideATitle: "Psalms of Love", sideBArtist: "Dillinger", sideBTitle: "You Me Love"),
        ]

        do {
            let discs = try mockData.map { mock in
                let disc = try Disc.create(sideAArtistName: mock.sideAArtist, sideATitle: mock.sideATitle, sideBArtistName: mock.sideBArtist, sideBTitle: mock.sideBTitle, in: context)
                if mock.sideATitle == "Mack the Knife", let url = Bundle.main.url(forResource: "MackTheKnife", withExtension: "png"), let data = try? Data(contentsOf: url) {
                    print("Loading \(data.count) bytes of Mack the Knife...")
                    if let image = CGImage.fromPNGData(data) {
                        print("Loaded image \(String(describing: image))")
                        let dbImage = DiscImage(context: context)
                        dbImage.image = image
                        disc.image = dbImage
                    } else {
                        print("Error loading CGImage from data")
                    }
                }
                return disc
            }
            try context.save()
            _mocks = discs
        }
        catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

extension Jukebox {
    static var _mock: Jukebox! = nil

    var type: JukeboxType {
        return JukeboxType(rawValue: typeName ?? "") ?? .undefined
    }

    static func createMocks(in context: NSManagedObjectContext) {
        if _mock != nil { return }

        do {
            let jukebox = Jukebox(context: context)
            jukebox.name = "Jukebox"
            jukebox.typeName = JukeboxType.seeburgM100.rawValue

            let program = Program(context: context)
            program.name = "Test Program"
            program.createdAt = Date()
            program.jukebox = jukebox

            let discs = Disc.mocks
            let selection = Selection(context: context)
            selection.slot = .song("A", 1)
            selection.disc = discs.first!
            selection.program = program

            try context.save()
            _mock = jukebox
        }
        catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static var mockProgram: Program {
        return _mock.allPrograms.first!
    }
}

//extension JukeboxProgram {
//    static var mock: JukeboxProgram {
//        let program = JukeboxProgram()
//        program.place(.mocks[0], at: .song("A", 1))
//        program.place(.mocks[1], at: .song("B", 1))
//        program.place(.mocks[2], at: .song("B", 5))
//        program.place(.mocks[3], at: .song("A", 3))
//        return program
//    }
//}

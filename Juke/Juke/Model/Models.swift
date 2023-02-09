//
//  Models.swift
//  Juke
//
//  Created by devin chalmers on 2/5/23.
//

import Foundation
import CloudKit
import CoreData
import CoreGraphics

enum DataError: LocalizedError {
    case mustNotBeBlank(String)
}

extension Artist {
    static func named(_ name: String, in context: NSManagedObjectContext) throws -> Artist? {
        let fetchRequest = NSFetchRequest<Artist>(entityName: "Artist")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        let artists = try context.fetch(fetchRequest)
        if let artist = artists.first {
            NSLog("Found existing artist \(name)")
            return artist
        } else {
            NSLog("Creating artist \(name)")
            let artist = Artist(context: context)
            artist.name = name
            return artist
        }
    }
}

extension Disc {
    public override var description: String {
        return "\(sideAArtist?.name ?? "??") - \(sideATitle ?? "??") / \(sideBTitle ?? "")"
    }

    public var discArtist: String {
        switch (sideAArtist?.name, sideBArtist?.name) {
        case let (.some(artistA), .some(artistB)) where artistA == artistB:
            return artistA
        case let (.some(artistA), .some(artistB)):
            return "\(artistA) / \(artistB)"
        default:
            return ""
        }
    }

    public var sideA: String {
        sideATitle ?? "(unknown)"
    }

    public var sideB: String {
        sideBTitle ?? "(unknown)"
    }

    public var creationDate: String {
        createdAt?.ISO8601Format(.iso8601(timeZone: .current))  ?? "(unknown)"
    }
}

// this doesn't seem to be a good pattern--no way to interchange a CoreData object without a MOC,
// which the Disc type doesn't have. probably all these models should be wrapped in ViewModels.
// there may be a special way to do this with CloudKit but these APIs are so hard to read.
//extension UTType {
//    static var single: UTType { UTType(exportedAs: "org.doormouse.single") }
//}
//extension Disc: Transferable {
//    public static var transferRepresentation: some TransferRepresentation {
//        ProxyRepresentation(exporting: { disc in
//            disc.objectID.uriRepresentation()
//        }, importing: { uri in
//            NSLog("Importing disc \(uri))!")
//            let moc = PersistenceController.preview.container.viewContext
//            let psc = moc.persistentStoreCoordinator!
//            let objectID = psc.managedObjectID(forURIRepresentation: uri)
//            let object = try PersistenceController.preview.container.viewContext.existingObject(with: objectID!) as! Disc
//            return object
////            return Disc()
//        })
////        CKShareTransferRepresentation() { disc in
////            return disc.objectID
////        }
////        DataRepresentation(contentType: .single, exporting: { disc in
////            disc.objectID.uriRepresentation().dataRepresentation
////        }, importing: { objectURIData in
////            let moc = PersistenceController.preview.container.viewContext
////            guard let psc = moc.persistentStoreCoordinator else {
////                NSLog("Error: No persistent store coordinator!")
////                return nil
////            }
////            guard let uri = URL(dataRepresentation: objectURIData, relativeTo: nil) else {
////                NSLog("Invalid URI data")
////                return nil
////            }
////            let objectID = psc.managedObjectID(forURIRepresentation: uri)
////            let object = try PersistenceController.preview.container.viewContext.existingObject(with: objectID)
////            return object
////        })
//    }
//}

extension DiscImage {
    public var image: CGImage? {
        get {
            CGImage.fromPNGData(imageData)
        }
        set {
            imageData = newValue?.pngData ?? nil
        }
    }
}

extension Jukebox {
    public var allPrograms: [Program] {
        let set = programs as? Set<Program> ?? []
        return set.sorted {
            ($0.createdAt ?? Date()) < ($1.createdAt ?? Date())
        }
    }

    public var type: JukeboxType {
        JukeboxType(rawValue: typeName ?? "") ?? .undefined
    }
}

extension Selection {
    var slot: JukeboxSlotContents {
        get {
            return JukeboxSlotContents(stringValue: slotName ?? "")
        }
        set {
            slotName = newValue.stringValue
        }
    }

    var slotMapping: (JukeboxSlotContents, Disc)? {
        if let disc = disc {
            return (slot, disc)
        } else {
            return nil
        }
    }
}

extension Program {
    var allSelections: Set<Selection> { selections as? Set<Selection> ?? [] }

    var selectionMap: [JukeboxSlotContents:Disc] {
        Dictionary(uniqueKeysWithValues: allSelections.compactMap(\.slotMapping))
    }

    func selection(in slot: JukeboxSlotContents) -> Selection? {
        allSelections.first(where: { $0.slot == slot })
    }

    func selection(for disc: Disc) -> Selection? {
        allSelections.first(where: { $0.disc == disc })
    }

    func place(_ disc: Disc, at slot: JukeboxSlotContents) {
        NSLog("Placing \(disc) in \(slot)")

        if let existingSelection = selection(for: disc) {
            managedObjectContext?.delete(existingSelection)
        }

        if let selection = selection(in: slot) {
            selection.disc = disc
        } else {
            let selection = Selection(context: managedObjectContext!)
            selection.slot = slot
            selection.disc = disc
            selection.program = self
        }
    }
}

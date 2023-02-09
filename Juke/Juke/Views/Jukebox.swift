//
//  Jukebox.swift
//  Juke
//
//  Created by devin chalmers on 2/6/23.
//

import SwiftUI

struct JukeboxPanel: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Jukebox.createdAt, ascending: false)],
        animation: .default)
    private var jukeboxes: FetchedResults<Jukebox>

    @State var sidebarVisible = NavigationSplitViewVisibility.detailOnly
    @State var selectedProgramID: Program.ID?

    var allPrograms: [Program] {
        jukeboxes.flatMap(\.allPrograms)
    }

    let layout: JukeboxLayout

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisible) {
            List(selection: $selectedProgramID) {
                ForEach(jukeboxes) { jukebox in
                    Section(header: Text(jukebox.name ?? "(unknown)")) {
                        ForEach(jukebox.allPrograms) { program in
                            Text(program.name ?? "(unknown)")
                        }
                    }
                }
            }
        } detail: {
            if let program = allPrograms.first(where: { $0.id == selectedProgramID }) {
                ScrollView([.horizontal, .vertical]) {
                    JukeboxContentView()
                        .navigationTitle("\(program.jukebox?.name ?? "(unknown)"): \(program.name ?? "(unknown)")")
                        .environmentObject(program)
                }
            }
        }
    }

}

struct JukeboxContentView: View {
    @EnvironmentObject var program: Program

    var body: some View {
        let layout = program.jukebox?.type.layout ?? .empty
        let columns = Array(repeating: GridItem(.fixed(470)), count: layout.columns)
        return LazyVGrid(columns: columns) {
            ForEach(layout.sections, id: \.self) { section in
                if let section = section {
                    JukeboxSectionView(contents: section)
                } else {
                    VStack { }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
    }
}

struct JukeboxSectionView: View {
    let contents: JukeboxSection

    var body: some View {
        VStack(alignment: .center) {
            header(title: contents.title)
            JukeboxSlots(contents: contents)
        }
        .padding(8)
    }

    func header(title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.black)
            .frame(width: 200, height: 24)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 5)
            }
    }
}

struct JukeboxSlots: View {
    let contents: JukeboxSection

    let tileSize = CGSize(width: 200, height: 64)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< contents.cols, id: \.self) { col in
                VStack {
                    ForEach(0 ..< contents.rows, id: \.self) { row in
                        let slot = contents.slot(row, col)
                        let side = JukeboxSlot.LabelSide.alternating(col)
                        JukeboxSlot(slot: slot, labelSide: side, labelSize: tileSize)
                    }
                }

            }
        }
    }
}

struct JukeboxSlot: View {
    @Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext
    @EnvironmentObject private var program: Program
    
    @State var slot: JukeboxSlotContents
    @State var targeting = false

    enum LabelSide {
        case left
        case right

        static func alternating(_ number: Int, parity: Int = 1) -> LabelSide {
            return (number % 2 == parity) ? .left : .right
        }
    }

    let labelSide: LabelSide
    let labelSize: CGSize

    var body: some View {
        let disc = program.selection(in: slot)?.disc
        HStack(spacing: 4) {
            switch labelSide {
            case .left:
                slotLabels()
                // TODO: is there a better way to make draggable conditional?
                if let disc = disc {
                    discLabel(disc: disc)
                        .draggable(disc.objectID.uriRepresentation())
                } else {
                    discLabel(disc: disc)
                }
            case .right:
                if let disc = disc {
                    discLabel(disc: disc)
                        .draggable(disc.objectID.uriRepresentation())
                } else {
                    discLabel(disc: disc)
                }
                slotLabels()
            }
        }
    }

    func discLabel(disc: Disc?) -> some View {
        ZStack {
            switch slot {
            case .song:
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(targeting ? .accentColor : disc == nil ? .gray.opacity(0.2) : .white.opacity(0.8))
                    .shadow(radius: 5)
                    .dropDestination(for: URL.self, action: dropDiscURLs, isTargeted: { targeting = $0 })

                if let disc = disc {
                    labelText(disc)
                }

            default:
                Text("")
            }
        }
        .frame(width: labelSize.width, height: labelSize.height)
    }

    func labelText(_ disc: Disc) -> some View {
        VStack(spacing: 2) {
            Text(disc.sideATitle ?? "")
            Text(disc.discArtist).bold()
            Text(disc.sideBTitle ?? "")
        }
        .font(.system(size: 12))
        .foregroundColor(.black)
    }

    func slotLabels() -> some View {
        VStack(spacing: 4) {
            Text(slot.stringA)
            Text("")
            Text(slot.stringB).frame(width: 24)
        }
        .font(.system(size: 10)).bold()
        .frame(width: 24)
    }

    func dropDiscURLs(items: [URL], dropPoint: CGPoint) -> Bool {
        NSLog("Got a drop! \(items)")
        guard let url = items.first,
              let store = viewContext.persistentStoreCoordinator,
              let objectID = store.managedObjectID(forURIRepresentation: url),
              let disc = try? viewContext.existingObject(with: objectID) as? Disc
        else {
            NSLog("Couldn't find disc with URL \(String(describing: items.first))!")
            return false
        }
        NSLog("Dropped a disc! \(disc)")
        program.place(disc, at: slot)
        return true
    }
}

extension Array {
    func inserting(_ element: Element, at index: Index) -> Self {
        return Array(prefix(index)) + [element] + Array(suffix(from: index))
    }
}

struct JukeboxPanel_Previews: PreviewProvider {
    static let abSlots = JukeboxSlotContents.bank("A", count: 5) + JukeboxSlotContents.bank("B", count: 5)
    static let abSection = JukeboxSection(title: "HIT TUNES", slots: abSlots, rows: 5, cols: 2)

    static var previews: some View {
        Group {
            JukeboxPanel(layout: JukeboxType.seeburgM100.layout)
            JukeboxSectionView(contents: abSection)
        }
        .environmentObject(Jukebox.mockProgram)
    }
}

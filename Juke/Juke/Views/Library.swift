//
//  Library.swift
//  Juke
//
//  Created by devin chalmers on 2/4/23.
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openWindow) private var openWindow

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Disc.createdAt, ascending: true)],
        animation: .default)
    private var discs: FetchedResults<Disc>

    enum ViewMode: String, CaseIterable, Hashable, Identifiable {
        case table
        case grid
        var id: Self { self }

        var symbolName: String {
            switch self {
            case .grid:  return "square.grid.2x2"
            case .table: return "list.bullet"
            }
        }
    }
    @State private var viewMode = ViewMode.grid

    @State private var selectedDiscID: Disc.ID?

    @State private var editingContext: NSManagedObjectContext?
    @State private var editingDisc: Disc?

    var body: some View {
        contentView
            .toolbar {
                ToolbarItem {
                    Button(action: showJukebox) {
                        Label("Show Jukebox", systemImage: "rectangle.grid.1x2")
                        Text("Program Jukebox")
                    }
                }
                ToolbarItem {
                    Picker("Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Image(systemName: mode.symbolName)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                ToolbarItem {
                    Button(action: addDisc) {
                        Label("Add Disc", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingDisc) { disc in
                DiscEditor(disc: disc)
            }
            .navigationTitle("Library")
    }

    func showJukebox() {
        openWindow(id: "jukebox")
    }

    var contentView: some View {
        switch viewMode {
        case .table: return AnyView(DiscsTable(selectedDiscID: $selectedDiscID, editingDisc: $editingDisc, discs: discs))
        case .grid:  return AnyView(gridView)
        }
    }

    var gridView: some View {
        let layout = [ GridItem(.adaptive(minimum: 256)) ]

        return ScrollView {
            LazyVGrid(columns: layout) {
                ForEach(discs) { disc in
                    GridTile(disc: disc, isSelected: .constant(disc.id == selectedDiscID))
                        .onTapGesture {
                            selectedDiscID = disc.id
                        }
                        .simultaneousGesture(TapGesture(count: 2).onEnded {
                            editingDisc = disc
                        })
                        .draggable(disc.objectID.uriRepresentation())
                }
            }.padding(16)
        }
    }

    private func gridTile(for disc: Disc) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(lineWidth: 3)
                            .foregroundColor(selectedDiscID == disc.id ? .accentColor : .primary)
                            .background {
                                image(for: disc)
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
            titleCard(for: disc)
                .padding(16)
                .background(.ultraThinMaterial)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(width: 256, height: 256)
    }

    func image(for disc: Disc) -> some View {
        ZStack {
            if let image = disc.image?.image {
                Image(nsImage: image.nsImage)
                    .resizable()
            } else {
                Image(systemName: "record.circle")
                    .resizable()
                    .opacity(0.1)
                    .padding(16)
            }
        }
    }

    func titleCard(for disc: Disc) -> some View {
        VStack(alignment: .center) {
            Text(disc.sideATitle ?? "")
            Text(disc.discArtist).font(.headline)
            Text(disc.sideBTitle ?? "")
        }
    }

    private func addDisc() {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext

        editingDisc = Disc(context: childContext)
        editingContext = childContext
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { discs[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct DiscsTable: View {
    @Binding var selectedDiscID: Disc.ID?
    @Binding var editingDisc: Disc?

    @State var discs: FetchedResults<Disc>

    private var selectedDisc: Disc? {
        discs.first(where: { $0.id == selectedDiscID })
    }

    var body: some View {
        Table(discs, selection: $selectedDiscID) {
            TableColumn("Artist(s)", value: \.discArtist)
            TableColumn("Side A", value: \.sideA)
            TableColumn("Side B", value: \.sideB)
            TableColumn("Added", value: \.creationDate)
        }
        .contextMenu(forSelectionType: Disc.ID.self) { items in
            // edit, show in program...
        } primaryAction: { items in
            editingDisc = selectedDisc
        }
    }
}

struct GridTile: View {
    @State var disc: Disc
    @Binding var isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(lineWidth: 3)
                            .foregroundColor(isSelected ? .accentColor : .primary)
                            .background {
                                image(for: disc)
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
            titleCard(for: disc)
                .padding(16)
                .background(.ultraThinMaterial)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(width: 256, height: 256)
    }

    func image(for disc: Disc) -> some View {
        ZStack {
            if let image = disc.image?.image {
                Image(nsImage: image.nsImage)
                    .resizable()
            } else {
                Image(systemName: "record.circle")
                    .resizable()
                    .opacity(0.1)
                    .padding(16)
            }
        }
    }

    func titleCard(for disc: Disc) -> some View {
        VStack(alignment: .center) {
            Text(disc.sideATitle ?? "")
            Text(disc.discArtist).font(.headline)
            Text(disc.sideBTitle ?? "")
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            GridTile(disc: Disc.mocks.first!, isSelected: .constant(false))
                .previewDisplayName("Grid Tile")
        }
    }
}

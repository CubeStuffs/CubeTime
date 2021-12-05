//
//  TimeListView.swift
//  txmer
//
//  Created by Tim Xie on 24/11/21.
//

import Foundation
import SwiftUI
import CoreData

/*
enum buttonMode {
    case isAscending
    case isDescending
}
 */

enum SortBy {
    case date
    case time
}

class TimeListManager: ObservableObject {
    @Published var solves: [Solves]?
    @Published var fetchError: NSError?
    @Binding var currentSession: Sessions?
    let managedObjectContext: NSManagedObjectContext
    @Published var sortBy: Int = 0
    var ascending = true
    
    private let fetchRequest = NSFetchRequest<Solves>(entityName: "Solves")
    
    init (currentSession: Binding<Sessions?>, managedObjectContext: NSManagedObjectContext) {
        self._currentSession = currentSession
        self.managedObjectContext = managedObjectContext
        fetchRequest.predicate = NSPredicate(format: "session == %@", currentSession.wrappedValue!)
        resort()
    }
    
    func resort() {
        if sortBy == 0 {
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Solves.date, ascending: ascending)]
        } else {
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Solves.time, ascending: ascending)]
        }
        do {
            try solves = managedObjectContext.fetch(fetchRequest)
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

@available(iOS 15.0, *)
struct TimeListView: View {
    @Binding var currentSession: Sessions?
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @StateObject var timeListManager: TimeListManager
    
     
    //let descendingButtonIcon: Image = Image(systemName: "chevron.down.circle")
    //var buttonIcon: String = userLastState
    
    private let columns = [
        // GridItem(.adaptive(minimum: 112), spacing: 11)
        GridItem(spacing: 10),
        GridItem(spacing: 10),
        GridItem(spacing: 10)
    ]
    
    init (currentSession: Binding<Sessions?>, managedObjectContext: NSManagedObjectContext) {
        self._currentSession = currentSession
        self._timeListManager = StateObject(wrappedValue: TimeListManager(currentSession: currentSession, managedObjectContext: managedObjectContext))
        //fetchRequest = NSFetchRequest<Solves>(entity: Solves.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Solves.date, ascending: true)], predicate: NSPredicate(format: "session == %@", self.currentSession!))
        
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6) /// todo make so user can change colour/changes dynamically with system theme - but when dark mode, change systemgray6 -> black (or not full black >:C)
                /// YES FULL BLACK FOR AMOLED DO YOU HATE YOUR BATTERY LIFE
                    .ignoresSafeArea()
                
                
                ScrollView() {
                    ZStack {
                        VStack {
                            
                            HStack (alignment: .center) {
                                Text(currentSession!.name!)
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                                    .foregroundColor(Color(UIColor.systemGray))
                                Spacer()
                                
                                Text("SQUARE-1")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(Color(UIColor.systemGray))
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            
                            
                            HStack {
                                
                                
                                Spacer()
                                
                                Picker("Sort Method", selection: $timeListManager.sortBy) {
                                    Text("Sort by Date").tag(0)
                                    Text("Sort by Time").tag(1)
                                }
                                .onChange(of: timeListManager.sortBy) {_ in
                                    timeListManager.resort() // TODO make this work automatically in the TimeListManager
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(maxWidth: 200, alignment: .center)
                                .padding(.top, -6)
                                .padding(.bottom, 4)
                                
                               
                                Spacer()
                            }
                                 
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(timeListManager.solves!, id: \.self) { item in
                                    TimeCard(solve: item)
                                        .environment(\.managedObjectContext, managedObjectContext)
                                }
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            
                            Spacer()
                        }
                        .padding(.top, -6)
                        .padding(.bottom, -6)
                        
                        
                        VStack /* (alignment: .center)*/ {
                            HStack {
                                Spacer()
                                
                                Button {
                                    timeListManager.ascending.toggle()
                                    timeListManager.resort()
                                    // let sortDesc: NSSortDescriptor = NSSortDescriptor(key: "date", ascending: sortAscending)
                                    //solves.sortDescriptors = [sortDesc]
                                } label: {
                                    Image(systemName: timeListManager.ascending ? "chevron.up.circle" : "chevron.down.circle")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .padding(.trailing, 16.5) /// TODO don't hardcode padding
                                .offset(y: (32 / 2) - (SetValues.iconFontSize / 2) + 6 + 18)
                            }
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Session Times")
                .toolbar {
                    Button {
                        print("button tapped")
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                //.frame(maxHeight: UIScreen.screenHeight)
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
/* TODO make previews that take ags work
@available(iOS 15.0, *)
struct TimeListView_Previews: PreviewProvider {
    static var previews: some View {
        TimeListView()
    }
}
*/

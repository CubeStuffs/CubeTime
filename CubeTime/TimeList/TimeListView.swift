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
    @Published var solves: [Solves]
    private var allsolves: [Solves]
    @Binding var currentSession: Sessions
    @Published var sortBy: Int = 0 {
        didSet {
            self.resort()
        }
    }
    @Published var filter: String = "" {
        didSet {
            self.refilter()
        }
    }
    var ascending = false
    
    init (currentSession: Binding<Sessions>) {
        self._currentSession = currentSession
        self.allsolves = currentSession.wrappedValue.solves!.allObjects as! [Solves]
        self.solves = allsolves
        resort()
    }
    
    func delete(_ solve: Solves) {
        guard let index = allsolves.firstIndex(of: solve) else { return }
        allsolves.remove(at: index)
        guard let index = solves.firstIndex(of: solve) else { return }
        solves.remove(at: index)
    }
    
    func resort() {
        allsolves = allsolves.sorted{
            if sortBy == 0 {
                if ascending {
                    return $0.date! < $1.date!
                } else {
                    return $0.date! > $1.date!
                }
            } /*else {
                if ascending {
                    return timeWithPlusTwoForSolve($0) < timeWithPlusTwoForSolve($1)
                } else {
                    return timeWithPlusTwoForSolve($0) > timeWithPlusTwoForSolve($1)
                }
            }*/
            else {
                let pen0 = PenTypes(rawValue: $0.penalty)!
                let pen1 = PenTypes(rawValue: $1.penalty)!
                
                if (pen0 != .dnf && pen1 != .dnf) || (pen0 == .dnf && pen1 == .dnf) {
                    if ascending {
                        return timeWithPlusTwoForSolve($0) < timeWithPlusTwoForSolve($1)
                    } else {
                        return timeWithPlusTwoForSolve($0) > timeWithPlusTwoForSolve($1)
                    }
                } else if pen0 == .dnf && pen1 != .dnf {
                    return !ascending
                } else {
                    return ascending
                }
            }
        }
        solves = allsolves
        refilter()
    }
    
    
    func refilter() {
        if filter == "" {
            solves = allsolves
        } else {
            solves = allsolves.filter{ formatSolveTime(secs: $0.time).hasPrefix(filter) }
        }
    }
}



struct TimeListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    @Environment(\.sizeCategory) var sizeCategory
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @Binding var currentSession: Sessions
    
    @StateObject var timeListManager: TimeListManager
    
    @State var solve: Solves?
    @State var calculatedAverage: CalculatedAverage?
    
    @State var isSelectMode = false
    @State var selectedSolves: [Solves] = []
    
    private var columns: [GridItem] {
        if sizeCategory > ContentSizeCategory.extraLarge {
            return [GridItem(spacing: 10), GridItem(spacing: 10)]
        } else if sizeCategory < ContentSizeCategory.small {
            return [GridItem(spacing: 10), GridItem(spacing: 10), GridItem(spacing: 10), GridItem(spacing: 10)]
        } else {
            return [GridItem(spacing: 10), GridItem(spacing: 10), GridItem(spacing: 10)]
        }
    }
    
    init (currentSession: Binding<Sessions>, managedObjectContext: NSManagedObjectContext) {
        self._currentSession = currentSession
        // TODO FIXME use a smarter way of this for more performance
        self._timeListManager = StateObject(wrappedValue: TimeListManager(currentSession: currentSession))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                    .ignoresSafeArea()
                
                
                ScrollView {
                    LazyVStack {
                        SessionBar(name: currentSession.name!, session: currentSession)
                            .padding(.horizontal)
                        
                        
                        // REMOVE THIS IF WHEN SORT IMPELEMNTED FOR COMP SIM SESSIONS
                        if currentSession.session_type != SessionTypes.compsim.rawValue {
                            ZStack {
                                HStack {
                                    Spacer()
                                    
                                    Picker("Sort Method", selection: $timeListManager.sortBy) {
                                        Text("Sort by Date").tag(0)
                                        Text("Sort by Time").tag(1)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(maxWidth: 200, alignment: .center)
                                    .padding(.top, -6)
                                    .padding(.bottom, 4)
                                    
                                   
                                    Spacer()
                                }
                                
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        timeListManager.ascending.toggle()
                                        timeListManager.resort()
                                        // let sortDesc: NSSortDescriptor = NSSortDescriptor(key: "date", ascending: sortAscending)
                                        //solves.sortDescriptors = [sortDesc]
                                    } label: {
                                        Image(systemName: timeListManager.ascending ? "chevron.up.circle" : "chevron.down.circle")
                                            .font(.title3.weight(.medium))
                                    }
                                    .padding(.trailing)
                                    .padding(.top, -6)
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                        
                        
                        if currentSession.session_type != SessionTypes.compsim.rawValue {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(timeListManager.solves, id: \.self) { item in
                                    TimeCard(solve: item, timeListManager: timeListManager, currentSolve: $solve, isSelectMode: $isSelectMode, selectedSolves: $selectedSolves)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                let groups = ((currentSession as! CompSimSession).solvegroups!.array as! [CompSimSolveGroup])
                                
                                if groups.count != 0 {
                                    TimeBar(solvegroup: groups.last!, timeListManager: timeListManager, currentCalculatedAverage: $calculatedAverage, isSelectMode: $isSelectMode, current: true)
                                    
                                    if groups.last!.solves!.array.count != 0 {
                                        LazyVGrid(columns: columns, spacing: 12) {
                                            ForEach(groups.last!.solves!.array as! [Solves], id: \.self) { solve in
                                                TimeCard(solve: solve, timeListManager: timeListManager, currentSolve: $solve, isSelectMode: $isSelectMode, selectedSolves: $selectedSolves)
                                            }
                                        }
                                    }
                                    
                                    if groups.count > 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                    
                                } else {
                                    // re-enable when we have a graphic
//                                    Text("display the empty message")
                                }
                                
                                
                                
                                // TODO sorting
                                
                                
                                
                                
                                ForEach(groups, id: \.self) { item in
                                    if item != groups.last! {
                                        TimeBar(solvegroup: item, timeListManager: timeListManager, currentCalculatedAverage: $calculatedAverage, isSelectMode: $isSelectMode, current: false)
                                    }
                                }
                                 
                                 
                                 
                            }
                            .padding(.horizontal)
                         
                         
                        }
                         
                    }
                    .padding(.vertical, -6)
                }
                .navigationTitle(isSelectMode ? "Select Solves" : "Session Times")
                
                
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if isSelectMode {
                            Button {
                                isSelectMode = false
                                for object in selectedSolves {
                                    managedObjectContext.delete(object)
                                    withAnimation {
                                        timeListManager.delete(object)
                                    }
                                }
                                selectedSolves.removeAll()
                                withAnimation {
                                    if managedObjectContext.hasChanges {
                                        try! managedObjectContext.save()
                                    }
                                }
                            } label: {
                                Text("Delete Solves")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Color.red)
                            }
                            .tint(.red)
                            .buttonStyle(.bordered)
                            .clipShape(Capsule())
                            .controlSize(.small)
                        }
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if currentSession.session_type != SessionTypes.compsim.rawValue {
                            if isSelectMode {
                                Button {
                                    isSelectMode = false
                                    selectedSolves.removeAll()
                                } label: {
                                    Text("Cancel")
                                }
                            } else {
                                Button {
                                    isSelectMode = true
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.body.weight(.medium))
                                }
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.clear).frame(height: 50).padding(.top).padding(.bottom, SetValues.hasBottomBar ? 0 : nil)}
            }
            .if (currentSession.session_type != SessionTypes.compsim.rawValue) { view in
                view
                    .searchable(text: $timeListManager.filter, placement: .navigationBarDrawer)
            }
            
        }
        .accentColor(accentColour)
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $solve) { item in
            TimeDetail(solve: item, currentSolve: $solve, timeListManager: timeListManager)
                .environment(\.managedObjectContext, managedObjectContext)
        }
        
        .sheet(item: $calculatedAverage) { item in
            StatsDetail(solves: item, session: currentSession)
        }
    }
}

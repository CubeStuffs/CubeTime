import SwiftUI
import CoreData

enum Tab {
    case timer
    case solves
    case stats
    case sessions
    case settings
}

class TabRouter: ObservableObject {
    @Published var currentTab: Tab = .timer
}

struct TabIconWithBar: View {
    @Binding var currentTab: Tab
    let assignedTab: Tab
    let systemIconName: String
    var systemIconNameSelected: String
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                if currentTab == assignedTab {
                    Color.primary
                        .frame(width: 32, height: 2)
                        .clipShape(Capsule())
                        .matchedGeometryEffect(id: "underline", in: namespace, properties: .frame)
                        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
                        .offset(y: -48)
                    //                                                .padding(.leading, 14)
                } else {
                    Color.clear
                        .frame(width: 32, height: 2)
                        .offset(y: -48)
                }
            }
            
            TabIcon(currentTab: $currentTab, assignedTab: assignedTab, systemIconName: systemIconName, systemIconNameSelected: systemIconNameSelected)
        }
    }
}


struct TabIcon: View {
    @Binding var currentTab: Tab
    let assignedTab: Tab
    let systemIconName: String
    var systemIconNameSelected: String
    var body: some View {
        Image(
            systemName:
                currentTab == assignedTab ? systemIconNameSelected : systemIconName
        )
            .font(.system(size: 22))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if currentTab != assignedTab {
                    currentTab = assignedTab
                }
            }
    }
}



struct MainTabsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @Namespace private var namespace
    
    @StateObject var tabRouter: TabRouter = TabRouter()
    @StateObject var stopWatchManager: StopWatchManager
    
    @State var pageIndex: Int = 0
    @State var hideTabBar = false
    @State var currentSession: Sessions
    
    @State var showUpdates: Bool = false
    
    //    var shortcutItem: UIApplicationShortcutItem?
    
    
    @AppStorage("onboarding") var showOnboarding: Bool = true
    @AppStorage(asKeys.overrideDM.rawValue) private var overrideSystemAppearance: Bool = false
    @AppStorage(asKeys.dmBool.rawValue) private var darkMode: Bool = false
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    init(managedObjectContext: NSManagedObjectContext) {
        let lastUsedSessionURI = UserDefaults.standard.url(forKey: "last_used_session")
        
        /*
         if let shortcutItem = shortcutItem {
         self.shortcutItem = shortcutItem
         }
         */
        
        let fetchedSession: Sessions
        
        if lastUsedSessionURI == nil {
            fetchedSession = Sessions(context: managedObjectContext) // TODO make it playground
            fetchedSession.scramble_type = 1
            fetchedSession.session_type = SessionTypes.playground.rawValue
            fetchedSession.name = "Default Session"
            try! managedObjectContext.save()
            UserDefaults.standard.set(fetchedSession.objectID.uriRepresentation(), forKey: "last_used_session")
        } else {
            let objID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: lastUsedSessionURI!)!
            fetchedSession = try! managedObjectContext.existingObject(with: objID) as! Sessions // TODO better error handling
        }
        
        // https://swiftui-lab.com/random-lessons/#data-10
        self._stopWatchManager = StateObject(wrappedValue: StopWatchManager(currentSession: fetchedSession, managedObjectContext: managedObjectContext))
        
        self._currentSession = State(initialValue: fetchedSession)
    }
    
    
    func checkForUpdate() {
        let newVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
        
        let currentVersion = UserDefaults.standard.string(forKey: "currentVersion")
        
        if currentVersion == newVersion {
//            print("same")
        } else {
            if !showOnboarding {
                showUpdates = true
            }
            UserDefaults.standard.set(newVersion, forKey: "currentVersion")
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                switch tabRouter.currentTab {
                case .timer:
                    TimerView(pageIndex: $pageIndex, currentSession: $currentSession, managedObjectContext: managedObjectContext, hideTabBar: $hideTabBar)
                        .environment(\.managedObjectContext, managedObjectContext)
                        .environmentObject(stopWatchManager)
                        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                case .solves:
                    TimeListView(currentSession: $currentSession, managedObjectContext: managedObjectContext)
                        .environment(\.managedObjectContext, managedObjectContext)
                        .environmentObject(stopWatchManager)
                case .stats:
                    StatsView(currentSession: $currentSession, managedObjectContext: managedObjectContext)
                case .sessions:
                    SessionsView(currentSession: $currentSession)
                        .environment(\.managedObjectContext, managedObjectContext)
                        .environmentObject(stopWatchManager)
                    // TODO move this to SessionsView on tap
                        .onChange(of: currentSession) { newSession in
                            
                            UserDefaults.standard.set(newSession.objectID.uriRepresentation(), forKey: "last_used_session") // TODO what was i thinking move this logic into SessionsView
                            stopWatchManager.changeCurrentSession(newSession)
                            
                        }
                case .settings:
                    SettingsView(showOnboarding: $showOnboarding)
                        .environmentObject(stopWatchManager)
                }
                
                BottomTabsView(hide: $hideTabBar, currentTab: $tabRouter.currentTab, namespace: namespace)
                    .zIndex(1)
                    .ignoresSafeArea(.keyboard)
            }
            .sheet(isPresented: $showOnboarding, onDismiss: {
                pageIndex = 0
                removeBrokenSolvegroups(managedObjectContext)
            }) {
                OnboardingView(showOnboarding: showOnboarding, pageIndex: $pageIndex)
            }
            .sheet(isPresented: $showUpdates, onDismiss: {
                showUpdates = false
                removeBrokenSolvegroups(managedObjectContext)
            }) {
                Updates(showUpdates: $showUpdates)
            }
            .if(dynamicTypeSize != DynamicTypeSize.large) { view in
                view
                    .alert(isPresented: $showUpdates) {
                        Alert(title: Text("DynamicType Detected"), message: Text("CubeTime only supports standard DyanmicType sizes. Accessibility DynamicType modes are currently not supported, so layouts may not be rendered correctly."), dismissButton: .default(Text("Got it!")))
                    }
            }
            .onAppear(perform: checkForUpdate)
            
            /// attempted shortcut menu :tear:
//            .onChange(of: scenePhase) { newValue in
//                if newValue == .active {
//                    if let shortcutItem = shortcutItem {
//                        print("HERE")
//                        print(shortcutItem.type)
//
//                        tabRouter.currentTab = {
//                            switch shortcutItem.type {
//                            case "timer":
//                                return .timer
//                            case "timelist":
//                                return .solves
//                            case "stats":
//                                return .stats
//                            case "sessions":
//                                return .sessions
//                            default:
//                                return .timer
//                            }
//                        }()
//                    }
//                }
//            }
             
        }
        .preferredColorScheme(overrideSystemAppearance ? (darkMode ? .dark : .light) : nil)
        .tint(accentColour)
    }
}

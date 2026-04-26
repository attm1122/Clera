import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let persistence: AppPersistence
    let authProvider: AuthProviding
    let cloudSync: CloudSyncing?
    let crashReporter: CrashReporting
    let aiService: AIProviding
    private let migration: LocalToCloudMigration?
    private var authStateTask: Task<Void, Never>?

    // Entry
    var hasCompletedAuth: Bool
    var userProfile: UserProfile?
    var permissionState: PermissionState

    // Onboarding
    var hasCompletedOnboarding: Bool
    var skinProfile: SkinProfile
    var baselineSkinMap: SkinMap?
    var skinBaseline: SkinBaseline?

    // Main Data
    var currentProducts: [Product]
    var routineLogs: [RoutineLogEntry]
    var routineChanges: [RoutineChangeLogEntry]
    var sessions: [ScanSession]
    var skinMapHistory: [SkinMap]
    var experiments: [Experiment]
    var insights: [Insight]
    var weeklyInsights: [WeeklyInsight]
    var productIntelligenceReports: [ProductIntelligenceReport]
    var skinSessions: [SkinSession]
    var skinSessionResults: [SkinSessionResult]
    var nudges: [Nudge]
    var dailyAdvice: DailySkinAdviceResult?
    var dailyAdviceHistory: [DailySkinAdviceResult]

    // Settings
    var reminderSettings: ReminderSettings
    var privacySettings: PrivacySettings

    // Navigation
    var selectedTab: AppTab = .today
    var onboardingStep: OnboardingStep = .welcome

    // MARK: - Init

    init(
        persistence: AppPersistence = AppPersistence(),
        authProvider: AuthProviding = FirebaseAuthService(),
        cloudSync: CloudSyncing? = nil,
        crashReporter: CrashReporting = NoOpCrashReporter(),
        aiService: AIProviding = NoOpAIService(),
        migration: LocalToCloudMigration? = nil
    ) {
        self.persistence = persistence
        self.authProvider = authProvider
        self.cloudSync = cloudSync
        self.crashReporter = crashReporter
        self.aiService = aiService
        self.migration = migration

        if let state = persistence.load() {
            hasCompletedAuth = state.hasCompletedAuth
            userProfile = state.userProfile
            permissionState = state.permissionState
            hasCompletedOnboarding = state.hasCompletedOnboarding
            skinProfile = state.skinProfile
            baselineSkinMap = state.baselineSkinMap
            skinBaseline = state.skinBaseline
            currentProducts = state.currentProducts
            routineLogs = state.routineLogs
            routineChanges = state.routineChanges
            sessions = state.sessions
            skinMapHistory = state.skinMapHistory
            experiments = state.experiments
            insights = state.insights
            weeklyInsights = state.weeklyInsights
            productIntelligenceReports = state.productIntelligenceReports
            skinSessions = state.skinSessions
            skinSessionResults = state.skinSessionResults
            nudges = state.nudges
            reminderSettings = state.reminderSettings
            privacySettings = state.privacySettings
            selectedTab = state.selectedTab
            dailyAdvice = state.dailyAdvice
            dailyAdviceHistory = state.dailyAdviceHistory
            regenerateReports()
            regenerateNudges()
            Task { await regenerateDailyAdvice() }
        } else {
            hasCompletedAuth = false
            userProfile = nil
            permissionState = PermissionState()
            hasCompletedOnboarding = false
            skinProfile = SkinProfile()
            baselineSkinMap = nil
            skinBaseline = nil
            currentProducts = SampleData.defaultProducts
            routineLogs = []
            routineChanges = []
            sessions = []
            skinMapHistory = []
            experiments = []
            insights = SampleData.sampleInsights
            weeklyInsights = []
            productIntelligenceReports = []
            skinSessions = []
            skinSessionResults = []
            nudges = []
            reminderSettings = ReminderSettings()
            privacySettings = PrivacySettings()
            selectedTab = .today
            dailyAdvice = nil
            dailyAdviceHistory = []
        }

        // Subscribe to auth state changes
        authStateTask = Task { [weak self] in
            guard let self = self else { return }
            for await state in authProvider.authState {
                self.handleAuthState(state)
            }
        }
    }

    // MARK: - Production Factory

    static func makeProductionModel() -> AppModel {
        let crashReporter: CrashReporting = FirebaseConfiguration.isConfigured ? CrashlyticsReporter() : NoOpCrashReporter()
        crashReporter.configure()

        let authProvider: AuthProviding = FirebaseAuthService()
        let aiService: AIProviding = FirebaseConfiguration.isConfigured
            ? VertexAIService(crashReporter: crashReporter)
            : NoOpAIService()
        let profileRepo = FirestoreUserProfileRepository()
        let scanRepo = FirestoreSkinScanRepository()
        let routineRepo = FirestoreRoutineRepository()
        let cloudSync = CloudSyncService(
            authProvider: authProvider,
            profileRepo: profileRepo,
            scanRepo: scanRepo,
            routineRepo: routineRepo,
            crashReporter: crashReporter
        )
        let migration = LocalToCloudMigration(
            cloudSync: cloudSync,
            authProvider: authProvider,
            crashReporter: crashReporter
        )

        return AppModel(
            persistence: AppPersistence(),
            authProvider: authProvider,
            cloudSync: cloudSync,
            crashReporter: crashReporter,
            aiService: aiService,
            migration: migration
        )
    }

    // MARK: - Auth State Handling

    private func handleAuthState(_ state: CleraAuthState) {
        switch state {
        case .authenticated(let user):
            userProfile = UserProfile(name: user.displayName ?? user.email?.components(separatedBy: "@").first ?? "", email: user.email ?? "")
            hasCompletedAuth = true
            crashReporter.setUserId(user.uid)
            crashReporter.setCustomKey("auth_state", value: user.isAnonymous ? "anonymous" : "authenticated")
            crashReporter.log("AppModel: auth state = authenticated (\(user.isAnonymous ? "anonymous" : "email"))", level: .info)

            // Trigger migration for existing local data
            Task {
                let state = buildPersistedState()
                _ = await migration?.migrateIfNeeded(localState: state)
            }

        case .unauthenticated:
            userProfile = nil
            hasCompletedAuth = false
            crashReporter.setUserId(nil)
            crashReporter.setCustomKey("auth_state", value: "unauthenticated")
            crashReporter.log("AppModel: auth state = unauthenticated", level: .info)

        case .loading:
            break
        }
    }

    // MARK: - Computed

    var hasBaseline: Bool {
        sessions.contains(where: { $0.kind == .baseline })
    }

    var currentSkinMap: SkinMap {
        skinMapHistory.last ?? baselineSkinMap ?? SampleData.sampleSkinMap
    }

    var activeExperiment: Experiment? {
        experiments.first(where: { $0.isActive })
    }

    var canStartExperiment: Bool {
        activeExperiment == nil
    }

    var sortedSessions: [ScanSession] {
        sessions.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var latestSession: ScanSession? {
        sortedSessions.first
    }

    var todayRoutineLogs: [RoutineLogEntry] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return routineLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
    }

    var routineAdherenceThisWeek: Double {
        let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let logs = routineLogs.filter { $0.date >= startOfWeek }
        let expected = 14
        return expected > 0 ? Double(logs.filter { $0.followedRoutine }.count) / Double(expected) : 0
    }

    var todayScanned: Bool {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return sessions.contains { Calendar.current.isDate($0.createdAt, inSameDayAs: startOfDay) }
    }

    var latestSkinSession: SkinSession? {
        skinSessions.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    var latestSkinSessionResult: SkinSessionResult? {
        skinSessionResults.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    var morningProducts: [Product] {
        currentProducts.filter { $0.isActive && ($0.period == .morning || $0.period == .both) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var eveningProducts: [Product] {
        currentProducts.filter { $0.isActive && ($0.period == .evening || $0.period == .both) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Actions

    func completeAuth(name: String, email: String, password: String? = nil) async {
        crashReporter.log("AppModel: completeAuth called", level: .info)
        do {
            if let password = password {
                if let currentUser = authProvider.currentUser, currentUser.isAnonymous {
                    _ = try await authProvider.linkAnonymousAccount(email: email, password: password, name: name)
                } else {
                    _ = try await authProvider.signUp(email: email, password: password, name: name)
                }
            }
            userProfile = UserProfile(name: name, email: email)
            hasCompletedAuth = true
            persist()
        } catch let error as AuthError {
            crashReporter.recordError(error, context: ["action": "completeAuth", "email": email])
            crashReporter.log("Auth error: \(error.userMessage)", level: .error)
        } catch {
            crashReporter.recordError(error, context: ["action": "completeAuth", "email": email])
        }
    }

    func logout() {
        crashReporter.log("AppModel: logout called", level: .info)
        Task {
            do {
                try await authProvider.logOut()
            } catch let error as AuthError {
                crashReporter.recordError(error, context: ["action": "logout"])
            } catch {
                crashReporter.recordError(error, context: ["action": "logout"])
            }
        }
    }

    func updatePermissions(_ state: PermissionState) {
        permissionState = state
        persist()
    }

    func completeOnboarding(skinProfile: SkinProfile, baselineMap: SkinMap) {
        self.skinProfile = skinProfile
        self.baselineSkinMap = baselineMap
        self.skinMapHistory = [baselineMap]
        hasCompletedOnboarding = true
        selectedTab = .today
        Task {
            await syncProfileToCloud()
            await regenerateDailyAdvice()
        }
        persist()
    }

    func recordSession(kind: ScanType, photos: [ScanPhoto], skinMap: SkinMap, note: String, checkIn: SkinMapCheckIn? = nil, scanQuality: ScanQualityMetadata? = nil) {
        let recorded = SessionRecorder.record(
            kind: kind,
            photos: photos,
            skinMap: skinMap,
            note: note,
            checkIn: checkIn,
            scanQuality: scanQuality,
            currentProducts: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            experiments: experiments,
            skinBaseline: skinBaseline,
            existingResults: skinSessionResults,
            existingSessions: skinSessions,
            existingProductIntel: productIntelligenceReports
        )

        sessions.append(recorded.session)
        skinMapHistory = recorded.updatedMapHistory
        skinSessionResults.append(recorded.result)
        skinSessions.append(recorded.legacySession)

        if let lastIndex = sessions.indices.last {
            sessions[lastIndex].skinMap = recorded.legacySession.skinMap
        }

        regenerateInsights()
        regenerateReports()
        Task {
            await syncScanToCloud(recorded.session)
            await regenerateDailyAdvice()
        }
        persist()
    }

    func addProduct(_ product: Product) {
        currentProducts.append(product)
        routineChanges.append(RoutineChangeLogEntry(productId: product.id, changeType: .added, notes: "Added to \(product.period.rawValue) routine"))
        Task { await regenerateDailyAdvice() }
        persist()
    }

    func removeProduct(id: UUID) {
        currentProducts.removeAll(where: { $0.id == id })
        routineChanges.append(RoutineChangeLogEntry(productId: id, changeType: .removed))
        Task { await regenerateDailyAdvice() }
        persist()
    }

    func logRoutine(_ entry: RoutineLogEntry) {
        routineLogs.append(entry)
        regenerateInsights()
        Task {
            await syncRoutineLogToCloud(entry)
            await regenerateDailyAdvice()
        }
        persist()
    }

    func startExperiment(_ experiment: Experiment) {
        guard canStartExperiment else { return }
        experiments.append(experiment)
        regenerateInsights()
        regenerateReports()
        persist()
    }

    func completeExperiment(id: UUID, result: ExperimentResult) {
        if let index = experiments.firstIndex(where: { $0.id == id }) {
            experiments[index].isActive = false
            experiments[index].endDate = .now
            experiments[index].result = result
        }
        regenerateInsights()
        regenerateReports()
        persist()
    }

    func updateSkinProfile(_ profile: SkinProfile) {
        skinProfile = profile
        Task {
            await syncProfileToCloud()
            await regenerateDailyAdvice()
        }
        persist()
    }

    func updateReminderSettings(_ settings: ReminderSettings) {
        reminderSettings = settings
        NotificationManager.shared.scheduleReminders(settings: settings)
        persist()
    }

    func updatePrivacySettings(_ settings: PrivacySettings) {
        privacySettings = settings
        persist()
    }

    func restartOnboarding() {
        hasCompletedOnboarding = false
        onboardingStep = .welcome
        persist()
    }

    // MARK: - Cloud Sync Helpers

    private func syncProfileToCloud() async {
        do {
            try await cloudSync?.uploadProfile(skinProfile)
        } catch let error as CloudSyncError {
            crashReporter.recordError(error, context: ["action": "syncProfile"])
        } catch {
            crashReporter.recordError(error, context: ["action": "syncProfile"])
        }
    }

    private func syncScanToCloud(_ session: ScanSession) async {
        do {
            try await cloudSync?.uploadScan(session)
        } catch let error as CloudSyncError {
            crashReporter.recordError(error, context: ["action": "syncScan", "scanId": session.id.uuidString])
        } catch {
            crashReporter.recordError(error, context: ["action": "syncScan", "scanId": session.id.uuidString])
        }
    }

    private func syncRoutineLogToCloud(_ entry: RoutineLogEntry) async {
        do {
            try await cloudSync?.uploadRoutineLog(entry)
        } catch let error as CloudSyncError {
            crashReporter.recordError(error, context: ["action": "syncRoutineLog", "logId": entry.id.uuidString])
        } catch {
            crashReporter.recordError(error, context: ["action": "syncRoutineLog", "logId": entry.id.uuidString])
        }
    }

    // MARK: - Private

    func regenerateInsights() {
        insights = ReportGenerator.generateInsights(
            sessions: sessions,
            routineLogs: routineLogs,
            experiments: experiments,
            existingInsights: insights
        )
    }

    func regenerateReports() {
        let intelReport = ReportGenerator.generateProductIntelligence(
            products: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            sessions: sessions
        )
        productIntelligenceReports = [intelReport]

        weeklyInsights = ReportGenerator.generateWeeklyInsight(
            sessions: sessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts,
            productIntelligence: intelReport
        ).map { [$0] } ?? []
    }

    func regenerateDailyAdvice() async {
        let inputs = DailySkinAdviceEngine.EngineInputs(
            skinProfile: skinProfile,
            latestSkinMap: currentSkinMap,
            sessions: sessions,
            routineLogs: routineLogs,
            currentProducts: currentProducts,
            timeOfDay: TimeOfDay.current()
        )

        let environment: CompositeEnvironmentProvider
        if let weatherKitEnv = await WeatherKitEnvironmentProvider.createIfAvailable() {
            environment = weatherKitEnv
        } else {
            environment = CompositeEnvironmentProvider(
                weather: PlaceholderWeatherProvider(),
                uv: PlaceholderUVProvider(),
                airQuality: PlaceholderAirQualityProvider()
            )
        }

        let advice = await DailySkinAdviceEngine.generateAdvice(
            inputs: inputs,
            environment: environment
        )
        dailyAdvice = advice
        if !dailyAdviceHistory.contains(where: { Calendar.current.isDate($0.generatedAt, inSameDayAs: advice.generatedAt) }) {
            dailyAdviceHistory.insert(advice, at: 0)
            dailyAdviceHistory = Array(dailyAdviceHistory.prefix(7))
        }
        DailyAdviceWidgetStore.write(result: advice, history: dailyAdviceHistory)
        NotificationManager.shared.scheduleDailyAdviceNotifications(advice: advice)
        persist()
    }

    func dismissNudge(id: UUID) {
        if let index = nudges.firstIndex(where: { $0.id == id }) {
            nudges[index].isDismissed = true
            NotificationManager.shared.cancelNudgeNotification(id: id)
            persist()
        }
    }

    @MainActor func regenerateNudges() {
        let previousHighPriority = nudges.filter { $0.priority == .high && !$0.isDismissed }.map(\.id)

        nudges = ReportGenerator.generateNudges(
            sessions: sessions,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            currentProducts: currentProducts,
            existingNudges: nudges
        )

        for nudge in nudges where nudge.priority == .high && !nudge.isDismissed && !previousHighPriority.contains(nudge.id) {
            NotificationManager.shared.scheduleNudgeNotification(nudge)
        }
    }

    private func persist() {
        persistence.save(buildPersistedState())
    }

    private func buildPersistedState() -> PersistedAppState {
        PersistedAppState(
            hasCompletedAuth: hasCompletedAuth,
            userProfile: userProfile,
            permissionState: permissionState,
            hasCompletedOnboarding: hasCompletedOnboarding,
            skinProfile: skinProfile,
            baselineSkinMap: baselineSkinMap,
            skinBaseline: skinBaseline,
            currentProducts: currentProducts,
            routineLogs: routineLogs,
            routineChanges: routineChanges,
            sessions: sessions,
            skinMapHistory: skinMapHistory,
            experiments: experiments,
            insights: insights,
            weeklyReports: [],
            weeklyInsights: weeklyInsights,
            productIntelligenceReports: productIntelligenceReports,
            dailyPlans: [],
            skinSessions: skinSessions,
            skinSessionResults: skinSessionResults,
            nudges: nudges,
            reminderSettings: reminderSettings,
            privacySettings: privacySettings,
            selectedTab: selectedTab,
            dailyAdvice: dailyAdvice,
            dailyAdviceHistory: dailyAdviceHistory
        )
    }
}

// MARK: - Enums

enum AppTab: String, CaseIterable, Identifiable, Codable {
    case today
    case map
    case routine
    case progress
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .map: "Map"
        case .routine: "Routine"
        case .progress: "Progress"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max.fill"
        case .map: "face.smiling"
        case .routine: "drop"
        case .progress: "chart.line.uptrend.xyaxis"
        case .profile: "person"
        }
    }
}

enum OnboardingStep: String, CaseIterable, Identifiable, Codable {
    case welcome
    case skinConsultation
    case baselineScan
    case initialSkinMap
    case complete
    var id: String { rawValue }
}

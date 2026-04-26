import Foundation

/// Centralised, tone-calibrated microcopy for the entire Clera experience.
///
/// Tone principles:
/// - Premium: Elevated but accessible. No slang, no clichés.
/// - Calm: Soft verbs, no urgency, no panic words.
/// - Supportive: "We're here with you", "Let's try", gentle encouragement.
/// - Simple: Short sentences, one idea per message.
/// - Non-clinical: "Visible signs" not "symptoms". "Reported changes" not "diagnosed".
/// - Trustworthy: Honest about limitations. Never overclaim precision.
enum CleraCopy {

    // MARK: - Onboarding

    enum Onboarding {
        static let welcomeTitle = "Welcome to Clera"
        static let welcomeSubtitle = "Let's get to know your skin"
        static let welcomeBody = "A few questions and a baseline scan are all we need to build your personal skin map."

        static let featureSkinMap = "Skin Map"
        static let featureSkinMapBody = "Track five facial zones with visual clarity."
        static let featureRoutine = "Routine Tracking"
        static let featureRoutineBody = "Log what you use and notice how your skin responds."
        static let featureExperiments = "Experiments"
        static let featureExperimentsBody = "Test one change at a time and see what works."
        static let featureProgress = "Progress"
        static let featureProgressBody = "Photo history and trends that build over time."

        static let getStarted = "Get started"
        static let stepPrefix = "Step"

        static let consultationTitle = "Skin Consultation"
        static let consultationBody = "Tell us about your skin so we can tailor your experience."
        static let skinTypeLabel = "Skin type"
        static let sensitivityLabel = "Sensitivity"
        static let primaryGoalLabel = "Primary goal"
        static let ageRangeLabel = "Age range"
        static let primaryConcernsLabel = "Primary concerns"
        static let `continue` = "Continue"

        static let baselineScanTitle = "Baseline Scan"
        static let baselineScanBody = "Find natural light and hold your phone about 30 cm from your face."
        static let tapToCapture = "Tap to capture"
        static let analyzing = "Creating your skin map…"

        static let initialSkinMapTitle = "Your Skin Map"
        static let initialSkinMapBody = "Here's what we noticed in your baseline scan. You can update this anytime."

        static let completeTitle = "You're all set"
        static let completeBody = "Your baseline is recorded. Start logging your routine and checking in daily to build your skin history."
        static let goToToday = "Go to Today"

        static let processing = "Processing…"
    }

    // MARK: - Auth

    enum Auth {
        static let createAccountTitle = "Create account"
        static let joinClera = "Join Clera"
        static let joinBody = "Track your skin journey with guided check-ins and clear visual comparisons."
        static let fullNamePlaceholder = "Full name"
        static let emailPlaceholder = "Email"
        static let passwordPlaceholder = "Password"
        static let createAccountButton = "Create account"
        static let alreadyHaveAccount = "Already have an account?"
        static let logIn = "Log in"

        static let welcomeBackTitle = "Welcome back"
        static let logInTitle = "Log in"
        static let logInBody = "Continue your skin journey."
        static let forgotPassword = "Forgot password?"
        static let dontHaveAccount = "Don't have an account?"
        static let signUp = "Sign up"

        static let passwordRecoveryTitle = "Password recovery"
        static let resetPasswordTitle = "Reset password"
        static let resetBody = "Enter your email and we'll send you a link to reset your password."
        static let sendResetLink = "Send reset link"
        static let resetLinkSent = "Reset link sent to"
        static let backToLogIn = "Back to log in"
    }

    // MARK: - Permissions

    enum Permissions {
        static let title = "Almost there"
        static let subtitle = "Enable permissions"
        static let body = "Clera needs a few permissions to help you track your skin journey."
        static let cameraTitle = "Camera"
        static let cameraBody = "To capture skin scans and track progress visually."
        static let photoLibraryTitle = "Photo Library"
        static let photoLibraryBody = "To save and compare your skin photos over time."
        static let notificationsTitle = "Notifications"
        static let notificationsBody = "To remind you of daily scans and routine check-ins."
        static let allow = "Allow"
        static let `continue` = "Continue"
    }

    // MARK: - Scan Flow

    enum ScanFlow {
        static let dailyScanTitle = "Daily Scan"
        static let reviewTitle = "Review your photo"
        static let reviewBody = "Take a moment to check your photo before saving it."
        static let close = "Close"
        static let captureAndReview = "Capture and review"
        static let captureAnglePrefix = "Capture"

        static let cameraError = "Camera error"
        static let startingCamera = "Starting camera…"
        static let cancel = "Cancel"

        static let faceIndicator = "Face"
        static let centreIndicator = "Centre"
        static let lightIndicator = "Light"
        static let sharpIndicator = "Sharp"

        static let threeAngleSet = "Three-angle set"
        static let capturedWithConsistentFraming = "Captured with consistent framing"
        static let retake = "Retake"

        static let optionalNoteLabel = "Optional note"
        static let optionalNotePlaceholder = "What changed since last time?"
        static let continueToCheckIn = "Continue to check-in"

        static let processingTitle = "Putting your scan together…"
        static let processingBody = "Checking lighting, angles, and clarity."

        static let scanCompleteTitle = "All set"
        static let scanResultsTitle = "Your snapshot"
        static let scanResultsBody = "Here's what we noticed today"
        static let overallChange = "Overall change"
        static let yourNote = "Your note"
        static let done = "Done"
    }

    // MARK: - Scan Guidance (Real-time feedback)

    enum ScanGuidance {
        static let positionFace = "Position your face in the frame"
        static let noFaceDetected = "We can't see your face yet"
        static let moveCloser = "Move a little closer"
        static let moveBack = "Move back slightly"
        static let centreFace = "Centre your face"
        static let turnRight = "Turn slightly right"
        static let turnLeft = "Turn slightly left"
        static let tiltDown = "Tilt your head down slightly"
        static let tiltUp = "Tilt your head up slightly"
        static let improveLighting = "The lighting looks a little uneven"
        static let holdSteady = "Hold steady"
        static let holdStillMessage = "Hold still"
        static let readyToScan = "Ready to scan"
        static let couldNotAnalyze = "Let's try that scan again"
        static let detectingFace = "Looking for your face..."
        static let reduceGlare = "Reduce glare on your face"
        static let reduceShadows = "Reduce shadows on your face"
        static let brighterLight = "Find a brighter spot"
        static let softerLight = "Softer light works best"
        static let scanning = "Scanning..."
        static let analysing = "Analysing your skin..."
        static let scanComplete = "Scan complete"
    }

    // MARK: - Scan Failures (Capture-time)

    enum ScanFailure {
        static let noFaceMessage = "We can't see your face yet. Make sure you're in the frame."
        static let noFaceAction = "Centre your face in the guide and hold still."

        static let multipleFacesMessage = "We spotted more than one face. Let's focus on just yours."
        static let multipleFacesAction = "Make sure you're the only person in frame and try again."

        static let offCentreMessage = "Your face is slightly off-centre."
        static let offCentreAction = "Move so your face sits in the middle of the guide."

        static let poorLightingMessage = "The lighting looks a little uneven."
        static let poorLightingAction = "Try facing a window or find softer, natural light."

        static let glareMessage = "There's a bit of glare on your face."
        static let glareAction = "Angle away from bright lights or windows to reduce glare."

        static let blurryMessage = "The photo looks a little soft."
        static let blurryAction = "Hold your phone steady and take a breath before capturing."

        static let tooCloseMessage = "You're a bit close to the camera."
        static let tooCloseAction = "Move back an arm's length so your whole face fits in the guide."

        static let tooFarMessage = "You're a bit far from the camera."
        static let tooFarAction = "Move a little closer so your face fills the guide."

        static let extremeAngleMessage = "Your head is tilted more than usual."
        static let extremeAngleAction = "Face the camera more directly for the best comparison."

        static let scanConfidenceLowMessage = "Your scan quality was lower than usual, so today's comparison is marked with lower confidence."
        static let scanConfidenceLowAction = "You can still save this scan. We'll note the quality in your timeline."
    }

    // MARK: - Check-In

    enum CheckIn {
        static let title = "Quick Check-In"
        static let subtitle = "How's your skin?"
        static let body = "Two or three quick questions help us understand what matters to you."

        static let followedRoutineQuestion = "Did you follow your routine?"
        static let followedRoutineLabel = "Followed routine"

        static let changesQuestion = "Any changes since last time?"
        static let newProductsLabel = "New or changed products"

        static let symptomsQuestion = "Any of these?"
        static let irritationLabel = "Irritation"
        static let drynessLabel = "Dryness"
        static let breakoutsLabel = "Breakouts"

        static let notesQuestion = "Anything else?"
        static let notesPlaceholder = "Optional notes…"

        static let `continue` = "Continue"
        static let skip = "Skip"
    }

    // MARK: - Skin Map

    enum SkinMap {
        static let title = "Your Skin"
        static let subtitle = "Skin Map"
        static let body = "Tap a zone to see details and track changes over time."
        static let zoneDetailsTitle = "Zone Details"

        static let currentStatus = "Current Status"
        static let visibleSigns = "Visible Signs"
        static let overallTrend = "Overall Trend"
        static let history = "History"
        static let noHistory = "No history yet. Daily check-ins build your picture over time."
        static let notes = "Notes"
        static let noNotes = "No notes for this zone."

        static let lookingClear = "Looking clear"
        static let checkInNotes = "Check-in Notes"
        static let routineLabel = "Routine"
        static let newProductsLabel = "New products"
    }

    // MARK: - Change Detection

    enum ChangeDetection {
        static let notEnoughData = "Not enough scans to spot a change yet."
        static let checkInSupports = " Your check-in supports this."
        static let checkInMismatch = " You mentioned this, but your scan looks calmer. Worth keeping an eye on."
        static let allComparisonsAgree = "All comparisons agree:"
        static let latestScanPrefix = "Latest scan:"
        static let threeScanPrefix = "Three-scan trend:"
        static let sevenDayPrefix = "Seven-day trend:"

        static func increasedExplanation(zone: String, metric: String, magnitude: String, mode: String, from: String, to: String) -> String {
            "Visible signs of \(metric) in \(zone) have \(magnitude) increased \(mode), from \(from) to \(to)."
        }

        static func decreasedExplanation(zone: String, metric: String, magnitude: String, mode: String, from: String, to: String) -> String {
            "Visible signs of \(metric) in \(zone) have \(magnitude) decreased \(mode), from \(from) to \(to)."
        }

        static func stableExplanation(zone: String, metric: String, mode: String, level: String) -> String {
            "Visible signs of \(metric) in \(zone) are stable \(mode) at \(level)."
        }
    }

    // MARK: - Session Pipeline

    enum Pipeline {
        static let baselineWelcome = "This is your first scan. We'll use it as your starting point."
        static let lowQualitySaved = "Your scan was saved, but the quality wasn't ideal. Trends will become clearer with your next scan."
        static let noPreviousSession = "We'll start comparing once you have a few more scans."
        static let noPreviousSessionAction = "Keep scanning daily. Comparisons appear after your next check-in."
        static let missingCheckIn = "We missed your check-in this time."
        static let missingCheckInAction = "Your plan will still be created, just with slightly lower confidence."
        static let noRoutine = "You haven't added any products yet."
        static let noRoutineAction = "Add a few products in the Routine tab to get personalised plans."
        static let inconsistentHistory = "Your scans have a few gaps, which makes patterns harder to spot."
        static let inconsistentHistoryAction = "Try to scan daily for the most reliable comparisons."
        static let uncertainPlan = "We're still learning your skin. Today's plan is gentle and simple."
        static let uncertainPlanAction = "Stick to a simple routine until we have more data."
        static let uncertainPlanMessage = "We're not quite sure what your skin needs yet. A gentle routine is safest while we learn."

        static let starterPlanFocus = "Start simple"
        static let starterCleanserName = "Gentle cleanser"
        static let starterCleanserInstruction = "Use a mild cleanser suited to your skin type."
        static let starterMoisturizerName = "Moisturiser"
        static let starterMoisturizerInstruction = "Apply a basic moisturiser to keep skin comfortable."
        static let starterSPFName = "SPF 30+"
        static let starterSPFInstruction = "Apply sunscreen every morning."
        static let starterAvoid = "Hold off on strong actives like retinol or acids until you have a simple routine in place."
        static let starterReasoningNoProducts = "You don't have any products saved yet."
        static let starterReasoningSimple = "A simple cleanse-moisturise-protect routine is the best place to start."
        static let starterReasoningAddProducts = "Add your products in the Routine tab to get personalised plans."

        static let qualityNoMetadata = "No quality data available for this scan."
        static let qualityBelowIdeal = "Scan quality was below ideal. Some readings may be less reliable."
        static let qualityOverexposed = "The image was a little too bright. Details may be harder to compare."
        static let qualityShadow = "Shadows were detected. Even lighting helps keep comparisons consistent."
        static let qualityBlurry = "The image was slightly soft. Try holding steadier next time."
        static let qualityLowSharpness = "The image lacked sharpness. Details may not be as clear."
        static let qualityLooksGood = "Scan quality looks good."
    }

    // MARK: - Daily Copilot

    enum DailyCopilot {
        static let focusSoothe = "Soothe and simplify"
        static let focusWatch = "Watch and wait"
        static let focusHydrate = "Hydrate and protect"
        static let focusSimple = "Keep it simple"
        static let focusReduce = "Reduce and reassess"
        static let focusTrack = "Get back on track"
        static let focusSimplifyActives = "Simplify your actives"
        static let focusMaintain = "Maintain and protect"

        static let barrierMoisturizerInstruction = "Apply generously to support your skin barrier."
        static let spfInstruction = "Apply generously. Reapply if you're outdoors."
        static let newProductInstruction = "Use as directed and watch for any changes."

        static let avoidActivesPrefix = "Give your actives a rest for now:"
        static let avoidMultipleActives = "Don't combine multiple actives tonight"
        static let avoidSensitivity = "Avoid anything that might increase sensitivity"
        static let avoidMorningRetinol = "Save retinol for your evening routine"
        static let avoidExfoliation = "Ease up on exfoliation this week"

        static let reasoningBase = "Your plan is based on your latest skin map, routine logs, and product use."
        static let reasoningIrritation = "You reported irritation recently, so we're keeping things gentle."
        static let reasoningDryness = "Dryness signals mean hydration is the priority right now."
        static let reasoningBreakouts = "Breakouts are being monitored. We're avoiding anything that might add stress to your skin."
        static let reasoningNewProduct = "A new product was added recently, so we're giving your skin time to adjust."
        static let reasoningWorsening = "Some zones are showing more visible signs. Simplifying your routine can help identify what's happening."
        static let reasoningImproving = "Your skin is trending in a good direction. We're keeping your routine steady."
        static let reasoningLowAdherence = "Routine consistency has been low. A simpler routine is easier to stick with."
        static let reasoningSkipActives = "We're pausing actives to let your skin settle. You can reintroduce them once things calm down."
        static let reasoningLowConfidence = "We don't have enough scan data yet for high-confidence recommendations. Daily check-ins help."

        static let viewTitle = "Your personalised plan"
        static let focusLabel = "Focus"
        static let whatToUse = "What to use"
        static let noProductsAssigned = "No products in your routine yet."
        static let optionalLabel = "Optional"
        static let whatToAvoid = "Pause for now"
        static let nothingToAvoid = "Nothing to pause right now."
        static let whyThisPlan = "Why this plan"
        static let notesLabel = "Notes"
        static let confidenceLabel = "Confidence"
        static let done = "Done"
    }

    // MARK: - Weekly Insights

    enum WeeklyInsight {
        static let disclaimer = "Clera tracks visible signs and reported changes only. This is not a medical diagnosis. If you have concerns about your skin, consult a dermatologist."

        static let titleImproving = "Your skin is looking up"
        static let titleWorsening = "A few things to keep an eye on"
        static let titleStable = "Holding steady"
        static let titleNoData = "Building your picture"

        static func improvingBody(zones: String, scanCount: Int) -> String {
            scanCount > 2
                ? "This week, visible signs improved in \(zones). With \(scanCount) scans, the trend looks steady."
                : "This week, visible signs improved in \(zones). Keep scanning to confirm the trend."
        }

        static func worseningBody(zones: String) -> String {
            "Visible signs increased in \(zones). Consider what changed — routine, products, sleep, or stress may be worth reviewing."
        }

        static let stableBodyCalm = "Your skin looks calm this week. No major changes in visible signs."
        static let stableBodyMixed = "No major shifts this week. Some zones are unchanged, which can be a good sign if things were already going well."
        static let noDataBody = "Scan a few more times this week to build a clearer picture."

        static let improvingDescription = "Visible signs have decreased. Worth monitoring to see if this continues."
        static let worseningDescription = "Visible signs have increased. Consider what may have changed in your routine or habits."
        static let mixedDescription = "Some visible signs improving, others increasing. Mixed signals this week."
        static let lookingClear = "Looking clear this week."
        static let noSignificantChange = "No significant change in visible signs."

        static func contributorRoutineLow(_ pct: Int) -> String { "Routine adherence was low this week (\(pct)%). Low consistency may make it harder to tell what's working." }
        static let contributorRoutineHigh = "Great routine consistency this week. This makes it easier to spot patterns."

        static let contributorNewProductWithIssues = "New product(s) introduced this week, and you reported some skin changes. These may be linked — worth monitoring for another week."
        static let contributorNewProductWatch = "New product(s) introduced this week. Watch for any changes over the next few days."
        static func contributorTooManyActives(_ count: Int) -> String { "You have \(count) active treatments in your routine. Using too many actives at once may be worth reviewing if you're seeing irritation or dryness." }

        static let contributorAllScansLowQuality = "All scans this week had lower image quality. These readings may be less reliable."
        static func contributorSomeScansLowQuality(count: Int, total: Int) -> String {
            "\(count) of \(total) scans had lower image quality. Some readings may be less reliable."
        }

        static func contributorIrritation(_ count: Int) -> String { "You reported irritation \(count) times this week. This is worth monitoring." }
        static func contributorDryness(_ count: Int) -> String { "You reported dryness \(count) times this week. Consider whether your moisturiser or environment changed." }
        static func contributorBreakouts(_ count: Int) -> String { "You reported new or increased breakouts \(count) times this week." }
        static let contributorNewProductLinked = "New products were used alongside reported skin changes. The timing may be linked, but other factors could also be involved."

        static let nextStepConsistency = "Focus on routine consistency for the next week. It's easier to spot patterns when you stick to a steady routine."
        static let nextStepSimplify = "Consider simplifying your routine. Try dropping one active treatment and see if your skin calms down."
        static func nextStepWatchZone(_ zone: String) -> String { "Keep an eye on \(zone). If it doesn't improve in the next few days, consider what changed around the time it started." }
        static let nextStepMonitorProduct = "Continue monitoring how your skin responds to the new product. Give it at least one more week before deciding."
        static let nextStepKeepStable = "Great progress. Keep your current routine stable so you can confirm what's working."
        static let nextStepKeepScanning = "Everything looks steady. Keep up your routine and scan daily to catch any early shifts."
        static let nextStepBuildPicture = "Continue your daily scans and routine logging to build a clearer picture."
    }

    // MARK: - Insight Engine

    enum InsightEngine {
        static func breakoutsImproved(from: String, to: String) -> String {
            "Visible signs of breakouts decreased from \(from) to \(to). Keep doing what you're doing."
        }
        static let rednessImproved = "Redness is looking calmer. Your routine may be working."
        static func breakoutsIncreased(from: String, to: String) -> String {
            "Visible signs of breakouts went from \(from) to \(to). Consider what changed in your routine or habits."
        }
        static func experimentWeekCheck(days: Int, zone: String) -> String {
            "You've been running this experiment for \(days) days. Have you noticed any changes in \(zone)?"
        }
        static func experimentCompleted(name: String, outcome: String, notes: String) -> String {
            "Your experiment \(outcome). \(notes)"
        }
        static func routineAdherenceLow(pct: Int) -> String {
            "You've followed your routine \(pct)% of the time recently. Consistency helps see what works."
        }
        static let routineAdherenceHigh = "You've been very consistent. This makes it easier to spot what products are helping."
        static func suggestExperiment(zone: String, issue: String) -> String {
            "\(zone) has consistent \(issue). Run a 2-week experiment to test one change and see if it helps."
        }
    }

    // MARK: - Product Intelligence

    enum ProductIntelligence {
        static let multipleAMExfoliantsTitle = "Multiple morning exfoliants"
        static func multipleAMExfoliantsBody(_ count: Int) -> String { "You have \(count) exfoliating products in your morning routine. Using multiple exfoliants at once may increase the chance of visible irritation or dryness." }
        static let multipleAMExfoliantsExplanation = "Exfoliating actives remove the outer layer of skin. Using multiple in the same routine may be too much for some skin types."
        static let multipleAMExfoliantsAction = "Consider using only one exfoliant per routine, or alternate days."

        static let multiplePMExfoliantsTitle = "Multiple evening exfoliants"
        static func multiplePMExfoliantsBody(_ count: Int) -> String { "You have \(count) exfoliating products in your evening routine. This may be too much for your skin barrier." }
        static let multiplePMExfoliantsExplanation = "Evening is when your skin repairs itself. Multiple exfoliants may interfere with this process and increase dryness."
        static let multiplePMExfoliantsAction = "Try using just one exfoliant in the evening, or reduce frequency to two or three times per week."

        static let highExfoliantCountTitle = "High exfoliant count"
        static func highExfoliantCountBody(_ count: Int) -> String { "You have \(count) exfoliating products across your routine. This is more than most routines need." }
        static let highExfoliantCountAction = "Review your products and keep the one that works best. More isn't always better."

        static let retinolAcidsConflict = "Retinol and acids can be too harsh when used together. They may increase dryness and visible irritation."
        static let vitaminCAcidsConflict = "Vitamin C and acids have different pH needs. Using them together may reduce effectiveness and increase sensitivity."
        static let benzoylRetinolConflict = "Benzoyl peroxide and retinol can be harsh when combined. Consider using them on alternate days."
        static let benzoylVitaminCConflict = "Benzoyl peroxide may oxidise vitamin C, making both less effective."

        static let ingredientConflictTitle = "Possible ingredient pairing issue"
        static func ingredientConflictAction(_ a: String, _ b: String) -> String { "Try using \(a) and \(b) on alternate days, or at different times." }

        static func newProductTitle(_ name: String) -> String { "New product: \(name)" }
        static func newProductBody(_ name: String) -> String { "\(name) was added recently. New products — especially those with active ingredients — can take time to adjust to." }
        static func newProductActiveExplanation(_ name: String) -> String { "Products with active ingredients often have an adjustment period. Mild dryness or sensitivity in the first one to two weeks is common." }
        static func newProductActiveAction(_ name: String) -> String { "Introduce \(name) slowly — start two or three times per week and increase as your skin adjusts." }

        static let multipleNewProductsTitle = "Multiple new products"
        static func multipleNewProductsBody(_ count: Int) -> String { "You added \(count) new products recently. When several are introduced at once, it's hard to tell which is helping or causing changes." }
        static let multipleNewProductsExplanation = "Introducing multiple products at once makes it difficult to identify what works. If you notice changes, you won't know which product to attribute them to."
        static let multipleNewProductsAction = "Consider adding one product at a time and waiting two weeks before introducing the next. This makes it easier to spot patterns."

        static let routineInconsistencyTitle = "Routine inconsistency"
        static func routineInconsistencyBody(_ pct: Int) -> String { "You've followed your routine \(pct)% of the time recently. Inconsistent use makes it harder to tell what's working." }
        static let routineInconsistencyExplanation = "Skincare ingredients often need consistent use to show results. Missing days or skipping steps can delay visible improvements."
        static let routineInconsistencyAction = "Try to stick to your routine for at least two weeks. Consistency is one of the best ways to see what products are helping."

        static let spfGapTitle = "Photosensitising actives without SPF"
        static let spfGapBody = "You use products that can increase sun sensitivity, but don't have SPF in your morning routine. This may worsen visible signs over time."
        static let spfGapExplanation = "Retinol, AHAs, and BHAs can make skin more sensitive to sunlight. Without SPF, visible signs like redness and dark spots may become more noticeable."
        static let spfGapAction = "Add a broad-spectrum SPF 30+ to your morning routine. This is especially important when using exfoliating or retinol products."

        static func skinMapCorrelationTitle(_ zone: String, _ metric: String) -> String { "\(zone) \(metric) increased" }
        static func skinMapCorrelationBody(_ zone: String, _ metric: String) -> String { "Visible signs of \(metric) in \(zone) have increased since new products were added. The timing may be linked, though other factors could also be involved." }
        static let skinMapCorrelationExplanation = "When a zone changes shortly after adding new products, it's worth considering whether those products may be contributing. Stress, sleep, diet, and environment can also play a role."
        static func skinMapCorrelationAction(_ zone: String, _ products: String) -> String { "Monitor \(zone) for another week. If it continues to change, consider pausing \(products) one at a time to identify the trigger." }

        static let viewTitle = "Routine Check"
        static let detectedRisks = "What we noticed"
        static let noIssues = "Your routine looks balanced"
        static let noIssuesBody = "Your current routine doesn't show any ingredient conflicts or overuse patterns."
        static let whyThisMatters = "Why this matters"
        static let noAdditionalContext = "No additional context needed."
        static let suggestedActions = "Suggested Actions"
        static let keepDoing = "Keep doing what you're doing."
        static let routineLooksGood = "Routine looks good"
        static let routineCheckBody = "Based on your current products, routine logs, and recent skin map changes."
    }

    // MARK: - Empty / Loading / Success States

    enum State {
        static let noScansTitle = "No scans yet"
        static let noScansBody = "Take your first scan to start building your photo timeline."
        static let noTrends = "Keep scanning to see trends."
        static let noMorningProducts = "No morning products yet."
        static let noEveningProducts = "No evening products yet."
        static let noRoutineChanges = "No changes yet. Add or remove products to see them here."
        static let noActiveExperiment = "No active experiment"
        static let noActiveExperimentBody = "Start one experiment at a time to clearly see what works."
        static let startExperiment = "Start Experiment"
        static let noPastExperiments = "No past experiments yet."
        static let completeBeforeNew = "Complete this experiment before starting a new one."
        static let noInsights = "Check in daily and we'll start spotting patterns."
        static let noZones = "No zone data available for this week."
        static let noContributors = "No clear contributors identified this week."
        static let noPhoto = "No photo"
    }

    // MARK: - Today View

    enum Today {
        static let goodMorning = "Good morning"
        static let goodAfternoon = "Good afternoon"
        static let goodEvening = "Good evening"
        static let checkedIn = "Checked in"
        static let dailySkinScan = "Daily Skin Scan"
        static let greatJob = "Great job today."
        static let capturePrompt = "Capture your skin to track changes."
        static let scanNow = "Scan now"
        static let scanAccessibilityLabel = "Start daily skin scan"
        static let scanAccessibilityHint = "Opens the camera to capture your skin"
        static let todaysRoutine = "Today's Routine"
        static func routineProgress(_ done: Int) -> String { "\(done)/2 done" }
        static let activeExperiment = "Active Experiment"
        static let quickActions = "Quick Actions"
        static let viewMap = "View Map"
        static let viewMapHint = "Open skin map"
        static let experiments = "Experiments"
        static let experimentsHint = "View active experiments"
        static let progress = "Progress"
        static let progressHint = "See your progress over time"
        static let latestInsights = "Latest Insights"
    }

    // MARK: - Progress

    enum Progress {
        static let title = "Your Journey"
        static let subtitle = "Progress"
        static let body = "Photo history and skin trends over time."
        static let thisWeeksInsight = "This Week's Insight"
        static let selectTwoScans = "Select 2 scans to compare"
        static let cancel = "Cancel"
        static let compare = "Compare"
        static let photoTimeline = "Photo Timeline"
        static func scansRecorded(_ count: Int) -> String { "\(count) scans recorded" }
        static func firstScan(_ date: String) -> String { "Your first scan was \(date)" }
        static let trends = "Trends"
        static let scanDetail = "Scan Detail"
        static let photos = "Photos"
        static let skinMap = "Skin Map"
        static let before = "Before"
        static let after = "After"
        static let skinMapComparison = "Skin Map Comparison"
        static let notes = "Notes"
    }

    // MARK: - Weekly Summary View

    enum WeeklySummary {
        static let title = "Weekly Summary"
        static let overallTrend = "Overall Skin Trend"
        static let zoneChanges = "Zone Changes"
        static let possibleContributors = "Possible Contributors"
        static let nextBestAction = "Next Best Action"
    }

    // MARK: - Routine

    enum Routine {
        static let title = "Your Routine"
        static let subtitle = "Products & Log"
        static let body = "Track what you use and how consistently you follow your routine."
        static let weeklyAdherence = "Weekly Adherence"
        static let basedOnLast7Days = "Based on the last 7 days"
        static let productIntelligence = "Product Intelligence"
        static let morning = "Morning"
        static let evening = "Evening"
        static let recentChanges = "Recent Changes"
        static let addProduct = "Add Product"
        static let newProductSheetTitle = "New Product"
        static let newProductSheetBody = "Add a product to your routine and tag its active ingredients."
        static let productNamePlaceholder = "Product name"
        static let productNameExample = "e.g. Niacinamide Serum"
        static let categoryLabel = "Category"
        static let periodLabel = "When to use"
        static let periodPickerLabel = "Period"
        static let addButton = "Add"
        static let activeIngredients = "Active Ingredients"
        static let activeIngredientsBody = "Select any actives this product contains. This helps detect conflicts and overuse."
    }

    // MARK: - Experiments

    enum Experiments {
        static let title = "Test & Learn"
        static let subtitle = "Experiments"
        static let body = "Run controlled tests to discover what works for your skin."
        static let activeExperiment = "Active Experiment"
        static let pastExperiments = "Past Experiments"
        static let tapToCheckIn = "Tap to check in or complete"
        static let experimentDetails = "Experiment Details"
        static let nameLabel = "Name"
        static let zoneLabel = "Zone"
        static let hypothesisLabel = "Hypothesis"
        static let durationLabel = "Duration"
        static let newExperiment = "New Experiment"
        static let start = "Start"
        static let checkInToday = "Check in today"
        static let dailyCheckIns = "Daily Check-ins"
        static func totalCheckIns(_ count: Int) -> String { "\(count) total" }
        static let noCheckIns = "No check-ins yet. Log your skin condition daily to track how this experiment is going."
        static let resultLabel = "Result"
        static let outcomeLabel = "Outcome"
        static let checkInPrompt = "How's your skin today?"
        static let checkInPlaceholder = "e.g. Slightly irritated, one new breakout"
        static let notesOptional = "Notes (optional)"
        static let notesPlaceholder = "Any observations?"
        static let dailyCheckIn = "Daily Check-in"
        static let save = "Save"
        static let noComment = "No comment"
    }

    // MARK: - Fallback

    enum Fallback {
        static let firstScanTitle = "First scan"
        static let firstScanBody = "This is your starting point. We'll compare future scans to this one."
        static let noPreviousDataTitle = "No previous data"
        static let noPreviousDataBody = "We'll start showing comparisons once you have a few more scans."
        static let missingRoutineTitle = "No routine yet"
        static let missingRoutineBody = "Add a few products to get personalised guidance."
        static let incompleteCheckInTitle = "Check-in incomplete"
        static let incompleteCheckInBody = "Your plan will still be created, just with slightly lower confidence."
        static let lowScanConfidenceTitle = "Scan quality was lower than usual"
        static let lowScanConfidenceBody = "You can still save this scan. We'll note the quality in your timeline."
        static let noClearTrendTitle = "No clear trend yet"
        static let noClearTrendBody = "Keep scanning daily. Patterns become clearer with more data."
    }

    // MARK: - Loading

    enum Loading {
        static let creatingSkinMap = "Creating your skin map…"
        static let puttingScanTogether = "Putting your scan together…"
        static let checkingQuality = "Checking lighting, angles, and clarity…"
        static let analysingChanges = "Looking for changes…"
        static let buildingPlan = "Building your plan…"
        static let fetchingHistory = "Fetching your history…"
        static let saving = "Saving…"
    }

    // MARK: - Success

    enum Success {
        static let scanSaved = "Scan saved"
        static let checkInSaved = "Check-in saved"
        static let productAdded = "Product added"
        static let experimentStarted = "Experiment started"
        static let experimentCompleted = "Experiment completed"
        static let routineUpdated = "Routine updated"
        static let settingsSaved = "Settings saved"
    }

    // MARK: - Profile

    enum Profile {
        static let settings = "Settings"
        static let reminders = "Reminders"
        static let privacy = "Privacy"
        static let account = "Account"
        static let restartOnboarding = "Restart Onboarding"
        static let logOut = "Log Out"
    }

    // MARK: - Display Name Overrides

    /// Warm, non-clinical display names for UI enums.
    // MARK: - What Changed

    enum WhatChanged {
        static let baselineMessage = "Baseline created. Clera will compare future scans against this reference."
        static let noMajorChanges = "No major changes detected. Your skin appears stable."
        static let allStable = "Your skin looks stable across all zones."
        static let inconsistentScan = "Some changes may be influenced by lighting or angle differences."
        static let consistencyNote = "This insight has lower confidence due to scan conditions."

        static func increased(zone: String, metric: String) -> String {
            "\(metric.capitalized) around the \(zone) appears increased compared to your baseline."
        }

        static func decreased(zone: String, metric: String) -> String {
            "\(metric.capitalized) around the \(zone) appears reduced compared to your baseline."
        }

        static func stable(zone: String, metric: String) -> String {
            "\(metric.capitalized) around the \(zone) looks stable."
        }

        static func allImproving(zones: String) -> String {
            "Great news — \(zones) appear to be improving."
        }
    }

    // MARK: - Timeline

    enum Timeline {
        static let title = "Skin Timeline"
        static let subtitle = "Your personal skin story"
        static let body = "Track how your skin changes over time and discover what works for you."
        static let viewTimeline = "View Timeline"
        static let beforeAfter = "Before & After"
        static let dragToCompare = "Drag to compare"
        static let noScansYet = "Start scanning to build your timeline."
        static let confidenceHigh = "High confidence"
        static let confidenceModerate = "Moderate confidence"
        static let confidenceLow = "Low confidence"
        static let consistencyWarning = "Some changes may be influenced by lighting or angle differences."
        static let routineMarkers = "Routine"
        static let environmentalMarkers = "Environment"
        static let whatChangedTitle = "What changed"
        static let primaryInsight = "Primary insight"
        static let secondaryInsight = "Secondary insight"
        static let showMore = "Show more"
        static let showLess = "Show less"
        static let patternUnlocked = "New pattern discovered"
        static let nudgeDismiss = "Dismiss"
        static let nudgeActionScan = "Scan now"
        static let nudgeActionTimeline = "View timeline"
        static let nudgeActionRoutine = "Log routine"
    }

    // MARK: - Routine Impact

    enum RoutineImpact {
        static let consistencyImprovement = "Your skin looks most stable when your routine is consistent. This may be linked to regular care."
        static let inconsistencyWorsening = "Some changes appeared during periods with fewer routine check-ins. Consistency may be worth monitoring."

        static func newProductReaction(product: String) -> String {
            "Some visible changes appeared after introducing \(product). This may be worth monitoring."
        }

        static func tooManyActives(count: Int) -> String {
            "You have \(count) active ingredients in your routine. If you're seeing dryness or irritation, simplifying may be worth considering."
        }

        static func routineGap(days: Int) -> String {
            "After a \(days)-day routine gap, some skin changes were visible. Consistency may help maintain stability."
        }
    }

    // MARK: - Environmental

    enum Environmental {
        static let highUV = "High UV levels during this period. Extra protection may be worth considering."
        static let lowHumidity = "Lower humidity during this period."
        static let poorAirQuality = "Poor air quality during this period."
        static let heatSpike = "Higher temperatures during this period."
        static let lowHumidityDrynessLink = "Lower humidity during this period may be contributing to visible dryness."
        static let heatBreakoutLink = "Higher temperatures during this period may be linked to visible changes."
    }

    // MARK: - Patterns

    enum Patterns {
        static let routineConsistencyStability = "Your skin tends to look more stable when your PM routine is consistent."

        static func zoneReactivity(zone: String) -> String {
            "Your \(zone.lowercased()) appears more reactive than other zones. It may be worth paying extra attention there."
        }

        static let productLagTime = "Your skin often shows visible changes 2–3 days after new product entries."

        static func scanTiming(period: String) -> String {
            "You tend to scan in the \(period). Scanning at a similar time may help with consistency."
        }

        static let mostStablePeriod = "Your skin looked most stable during a recent consistent period."
    }

    // MARK: - Nudges

    enum Nudges {
        static let followUpScan = "Your last scan showed changes around the chin. A follow-up scan could help confirm the trend."
        static let routineConsistencyGreat = "You've logged 3 consistent routines. Scan today to update your timeline."
        static let routineConsistencyLow = "Your routine check-ins have been a little sporadic. Consistency helps build a clearer picture."
        static let timelineForming = "Your timeline is starting to form. Keep scanning to see how your skin changes over time."
        static let timelineTrends = "Early trends are becoming visible in your timeline."
        static let timelinePatterns = "Routine patterns are getting clearer. Your timeline is getting more useful."
        static let timelinePersonal = "Clera can now detect more personal skin patterns. Your timeline is really coming alive."
        static let productMonitor = "You recently added a new product. A scan could help track how your skin responds."
        static let scanGapShort = "It's been a few days since your last scan. A quick check-in could help keep your timeline up to date."
        static let scanGapLong = "Your timeline is missing recent data. A scan today would help maintain accuracy."
    }

    enum DisplayNames {
        static let zoneSeverityClear = "Clear"
        static let zoneSeverityLow = "Mild"
        static let zoneSeverityModerate = "Moderate"
        static let zoneSeverityHigh = "Noticeable"

        static let zoneTrendImproving = "Improving"
        static let zoneTrendStable = "Steady"
        static let zoneTrendWorsening = "Changing"
        static let zoneTrendUnknown = "Not enough data"

        static let insightConfidenceHigh = "Confident"
        static let insightConfidenceModerate = "Fairly confident"
        static let insightConfidenceLow = "Still learning"

        static let scanStatusAccepted = "Looks good"
        static let scanStatusSavedLow = "Saved — quality could be better"
        static let scanStatusRejected = "Let's try again"

        static let riskSeverityCaution = "Caution"
        static let riskSeverityWarning = "Worth a look"
        static let riskSeverityInfo = "Note"

        static let failureNoFace = "No face detected"
        static let failureMultipleFaces = "Multiple faces"
        static let failureOffCentre = "Face not centred"
        static let failurePoorLighting = "Lighting could be better"
        static let failureGlare = "Harsh glare"
        static let failureBlurry = "Photo looks soft"
        static let failureTooClose = "Face too close"
        static let failureTooFar = "Face too far"
        static let failureExtremeAngle = "Head angle too steep"
        static let failureLowConfidence = "Scan quality low"
        static let failureMissingCheckIn = "Check-in missed"
        static let failureNoRoutine = "No routine yet"
        static let failureFirstScan = "First scan"
        static let failureInconsistentHistory = "Gaps in scan history"
        static let failureNoBaseline = "No baseline"
        static let failureUncertainPlan = "Plan is uncertain"
    }
}

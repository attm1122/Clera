import SwiftUI

struct RoutineView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showAddProduct = false
    @State private var newProductName = ""
    @State private var newProductCategory: ProductCategory = .cleanser
    @State private var newProductPeriod: Period = .morning
    @State private var selectedTags: Set<IngredientTag> = []
    @State private var showIntelligence = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.Routine.title,
                    title: CleraCopy.Routine.subtitle,
                    subtitle: CleraCopy.Routine.body
                )
                .padding(.top, CleraSpacing.xl)

                adherenceCard
                intelligenceCard
                morningRoutine
                eveningRoutine
                changeLog
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .sheet(isPresented: $showAddProduct) {
            addProductSheet
        }
        .sheet(isPresented: $showIntelligence) {
            if let report = appModel.productIntelligenceReports.first {
                ProductIntelligenceView(report: report)
            }
        }
    }

    private var adherenceCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                Text(CleraCopy.Routine.weeklyAdherence)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                HStack {
                    Text("\(Int(appModel.routineAdherenceThisWeek * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(CleraColor.accent)
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                            .fill(CleraColor.border)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                            .fill(CleraColor.accent)
                            .frame(width: max(0, geo.size.width * CGFloat(appModel.routineAdherenceThisWeek)), height: 8)
                    }
                }
                .frame(height: 8)

                Text(CleraCopy.Routine.basedOnLast7Days)
                    .font(.system(size: 12))
                    .foregroundStyle(CleraColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var intelligenceCard: some View {
        if let report = appModel.productIntelligenceReports.first, !report.risks.isEmpty {
            Button {
                showIntelligence = true
            } label: {
                CleraCard {
                    VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                        HStack {
                            Text(CleraCopy.Routine.productIntelligence)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            Spacer()
                            let warnings = report.risks.filter { $0.severity == .warning }.count
                            if warnings > 0 {
                                Text("\(warnings) warning\(warnings == 1 ? "" : "s")")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule(style: .continuous).fill(Color(hex: 0xC75B39)))
                            }
                        }

                        Text(report.risks.first?.title ?? "Review your routine")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)

                        Text(report.risks.first?.description ?? "")
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            EmptyView()
        }
    }

    private var morningRoutine: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            HStack {
                Label(CleraCopy.Routine.morning, systemImage: "sun.max.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
                Button {
                    showAddProduct = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CleraColor.accent)
                }
            }

            if appModel.morningProducts.isEmpty {
                Text(CleraCopy.State.noMorningProducts)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(appModel.morningProducts) { product in
                    productRow(product: product)
                }
            }
        }
    }

    private var eveningRoutine: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            HStack {
                Label(CleraCopy.Routine.evening, systemImage: "moon.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
            }

            if appModel.eveningProducts.isEmpty {
                Text(CleraCopy.State.noEveningProducts)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(appModel.eveningProducts) { product in
                    productRow(product: product)
                }
            }
        }
    }

    private func productRow(product: Product) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: CleraSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Text(product.category.displayName)
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                    Spacer()
                    Button {
                        appModel.removeProduct(id: product.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red.opacity(0.6))
                    }
                }

                if !product.ingredientTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(product.ingredientTags, id: \.self) { tag in
                            Text(tag.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: tag.color))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color(hex: tag.color).opacity(0.12))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color(hex: tag.color).opacity(0.25), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    private var changeLog: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Routine.recentChanges)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if appModel.routineChanges.isEmpty {
                Text(CleraCopy.State.noRoutineChanges)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(appModel.routineChanges.prefix(5)) { change in
                    HStack {
                        Image(systemName: change.changeType == .added ? "plus.circle" : "minus.circle")
                            .foregroundStyle(change.changeType == .added ? CleraColor.success : .red)
                        Text(change.changeType == .added ? "Added product" : "Removed product")
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textPrimary)
                        Spacer()
                        Text(change.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var addProductSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: CleraCopy.Routine.addProduct,
                        title: CleraCopy.Routine.newProductSheetTitle,
                        subtitle: CleraCopy.Routine.newProductSheetBody
                    )

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text(CleraCopy.Routine.productNamePlaceholder)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            TextField(CleraCopy.Routine.productNameExample, text: $newProductName)
                                .textFieldStyle(.plain)
                                .padding(CleraSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                        .fill(CleraColor.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                        .stroke(CleraColor.border, lineWidth: 1)
                                )
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text(CleraCopy.Routine.categoryLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Picker("Category", selection: $newProductCategory) {
                                ForEach(Array(ProductCategory.allCases), id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    CleraCard {
                        VStack(alignment: .leading, spacing: CleraSpacing.md) {
                            Text(CleraCopy.Routine.periodLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Picker(CleraCopy.Routine.periodPickerLabel, selection: $newProductPeriod) {
                                ForEach(Array(Period.allCases), id: \.self) { period in
                                    Text(period.displayName).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    ingredientTagPicker
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CleraCopy.ScanFlow.cancel) {
                        resetForm()
                        showAddProduct = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CleraCopy.Routine.addButton) {
                        let product = Product(
                            name: newProductName,
                            category: newProductCategory,
                            period: newProductPeriod,
                            ingredientTags: Array(selectedTags)
                        )
                        appModel.addProduct(product)
                        resetForm()
                        showAddProduct = false
                    }
                    .disabled(newProductName.isEmpty)
                }
            }
        }
    }

    private var ingredientTagPicker: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text(CleraCopy.Routine.activeIngredients)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Text(CleraCopy.Routine.activeIngredientsBody)
                    .font(.system(size: 12))
                    .foregroundStyle(CleraColor.textSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(IngredientTag.allCases, id: \.self) { tag in
                        let isSelected = selectedTags.contains(tag)
                        Button {
                            if isSelected {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            Text(tag.displayName)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? Color(hex: tag.color) : CleraColor.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(isSelected ? Color(hex: tag.color).opacity(0.15) : CleraColor.surface)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(isSelected ? Color(hex: tag.color).opacity(0.4) : CleraColor.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func resetForm() {
        newProductName = ""
        newProductCategory = .cleanser
        newProductPeriod = .morning
        selectedTags = []
    }
}

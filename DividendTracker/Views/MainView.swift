//
//  MainView.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 24/01/26.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        tabContent
    }
    
    var tabContent: some View {
        TabView(selection: $selectedTab) {
            DividendsView(mainViewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "dollarsign.circle.fill" : "dollarsign.circle")
                    Text("Dividends")
                }
                .tag(0)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            PortfolioView(mainViewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.pie.fill" : "chart.pie")
                    Text("Portfolio")
                }
                .tag(1)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(AppColors.PINK_COLOR)
        .onAppear() {
            if self.viewModel.remoteDividendData.isEmpty {
                Task {
                    await self.viewModel.loadEmails()
                }
            }
        }
    }
}

//MARK: Dividends Tab
struct DividendsView: View {
    @State private var showLogoutSheet = false
    @State private var selectedDataSource: DataSourceType = .api
    @ObservedObject var mainViewModel: MainViewModel
    
    private var totalData: [DividendItem] {
        return mainViewModel.getTotalDividendData()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Dividends")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !mainViewModel.isLoading && selectedDataSource == .api {
                        Button {
                            Task {
                                await mainViewModel.loadEmails()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.PINK_COLOR)
                        }
                    }
                    
                    Button {
                        showLogoutSheet = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.PINK_COLOR)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
                
                CardView(totalAmount: totalData.reduce(0) { $0 + $1.amount })
                    .padding(.horizontal, 20)
                
                HStack(spacing: 0) {
                    DataSourceTab(title: "API", isSelected: selectedDataSource == .api, isDisabled: mainViewModel.isLoading) {
                        selectedDataSource = .api
                    }
                    
                    DataSourceTab(title: "MANUAL", isSelected: selectedDataSource == .manual, isDisabled: mainViewModel.isLoading) {
                        selectedDataSource = .manual
                    }
                }
                .padding(.horizontal, 20)
                
                if selectedDataSource == .api {
                    ScrollView {
                        APITabContent(mainViewModel: mainViewModel)
                    }
                } else {
                    ManualTabContent(mainViewModel: mainViewModel)
                }
            }
        }
        .overlay(
            showLogoutSheet ? Color.black.opacity(0.5).ignoresSafeArea() : nil
        )
        .sheet(isPresented: $showLogoutSheet) {
            LogoutBottomSheet(handleUserLogout: handleUserLogout)
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(white: 0.5))
        }
    }
    
    func handleUserLogout() {
        mainViewModel.triggerLogout()
    }
}

struct DataSourceTab: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(isSelected ? AppColors.PINK_COLOR : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                
                Rectangle()
                    .fill(isSelected ? AppColors.PINK_COLOR : Color.clear)
                    .frame(height: 2)
            }
        }
        .disabled(isDisabled)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

enum DataSourceType {
    case api
    case manual
}

struct APITabContent: View {
    @ObservedObject var mainViewModel: MainViewModel
    
    private var remoteData: [DividendItem] {
        mainViewModel.getRemoteDividendData()
    }
    
    var body: some View {
        if mainViewModel.isLoading {
            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    ShimmerRow()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        } else {
            VStack(spacing: 12) {
                ForEach(remoteData) { dividend in
                    DividendRow(dividend: dividend)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

struct ManualTabContent: View {
    @ObservedObject var mainViewModel: MainViewModel
    
    @State private var selectedItem: DividendItem?
    @State private var showEditSheet = false
    @State private var showAddSheet = false
    
    private var manualData: [DividendItem] {
        mainViewModel.getManualDividendData()
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(manualData) { item in
                        ManualDividendRow(item: item)
                            .onLongPressGesture {
                                selectedItem = item
                                showEditSheet = true
                            }
                    }
                }
                .scrollIndicators(.visible)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            
            VStack {
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                        Text("Add new dividend")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.PINK_COLOR)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .overlay(
            (showEditSheet || showAddSheet) ? Color.black.opacity(0.6).ignoresSafeArea() : nil
        )
        .sheet(isPresented: $showEditSheet) {
            if let item = selectedItem {
                EditDividendBottomSheet(item: item, mainViewModel: mainViewModel)
                    .presentationDetents([.height(450)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(white: 0.04))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddDividendBottomSheet(mainViewModel: mainViewModel)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(white: 0.04))
        }
    }
}

struct ManualDividendRow: View {
    let item: DividendItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.PINK_COLOR.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.PINK_COLOR.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: 48, height: 48)
                
                Text(item.ticker)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.PINK_COLOR)
            }
            
            Text(item.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(String(format: "₹%.2f", item.amount))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.PINK_COLOR)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct CardView: View {
    let totalAmount: Double
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Circle()
                .fill(AppColors.PINK_COLOR.opacity(0.1))
                .blur(radius: 50)
                .frame(width: 160, height: 160)
                .offset(x: 200, y: -64)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("TOTAL ANNUAL YIELD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                
                Text(String(format: "₹%.2f", totalAmount))
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(AppColors.PINK_COLOR)
                    .shadow(color: AppColors.PINK_COLOR.opacity(0.4), radius: 12)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 140)
    }
}

struct DividendRow: View {
    let dividend: DividendItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.PINK_COLOR.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.PINK_COLOR.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: 48, height: 48)
                
                Text(dividend.ticker)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.PINK_COLOR)
            }
            
            Text(dividend.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(dividend.formattedAmount)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.PINK_COLOR)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct DividendItem: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let amount: Double
    let color: Color
    let percentage: String
    
    var formattedAmount: String {
        return String(format: "₹%.2f", amount)
    }
}

//MARK: Portfolio Tab
struct PortfolioView: View {
    @ObservedObject var mainViewModel: MainViewModel
    
    private var dividends: [DividendItem] {
        return mainViewModel.getTotalDividendData()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Portfolio")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 24) {
                    Text("ALLOCATION")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ZStack {
                        PieChartView(data: dividends)
                        
                        VStack(spacing: 4) {
                            Text("ASSETS")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(dividends.count)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 240)
                }
                .padding(.horizontal, 20)
                
                Text("TOP HOLDINGS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 24)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(dividends) { holding in
                            PortfolioRow(holding: holding)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct PieChartView: View {
    let data: [DividendItem]
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    private var segments: [(color: Color, percentage: Double)] {
        return data.map { item in
            (item.color, item.amount / totalAmount)
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        stops: createGradientStops(),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    )
                )
                .frame(width: 240, height: 240)
                .shadow(color: AppColors.PINK_COLOR.opacity(0.12), radius: 25)
            
            Circle()
                .fill(Color.black)
                .frame(width: 140, height: 140)
        }
    }
    
    private func createGradientStops() -> [Gradient.Stop] {
        var stops: [Gradient.Stop] = []
        var currentLocation: Double = 0.0
        
        for segment in segments {
            stops.append(.init(color: segment.color, location: currentLocation))
            currentLocation += segment.percentage
            stops.append(.init(color: segment.color, location: currentLocation))
        }
        
        return stops
    }
}

struct PortfolioRow: View {
    let holding: DividendItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(holding.color)
                .frame(width: 12, height: 12)
            
            Text(holding.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(holding.percentage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

//MARK: Bottom sheet common TextField Component
struct DividendBottomSheetTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var charLimit: Int
    @Binding var errorText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .padding()
                .frame(height: 56)
                .background(Color(white: 0.07))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: text) { oldValue, newValue in
                    if newValue.count > charLimit {
                        text = oldValue
                        errorText = "Character limit reached"
                    } else if newValue.count == charLimit && errorText != nil {
                        return
                    } else {
                        errorText = nil
                    }
                }
            
            if let text = errorText {
                Text(text)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(.red.opacity(0.6))
            }
        }
    }
}

//MARK: Add Dividend Bottom Sheet
struct AddDividendBottomSheet: View {
    @ObservedObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var ticker = ""
    @State private var tickerError: String?
    
    @State private var companyName = ""
    @State private var companyNameError: String?
    
    @State private var amount = ""
    @State private var amountError: String?
    
    var body: some View {
        ZStack {
            Color(white: 0.04).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Add New Dividend")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    DividendBottomSheetTextField(label: "TICKER", placeholder: "e.g., ITC", text: $ticker, charLimit: 20, errorText: $tickerError)
                    DividendBottomSheetTextField(label: "COMPANY NAME", placeholder: "e.g., ITC Limited", text: $companyName, charLimit: 100, errorText: $companyNameError)
                    DividendBottomSheetTextField(label: "DIVIDEND AMOUNT (₹)", placeholder: "e.g., 7750.00", text: $amount, keyboardType: .decimalPad, charLimit: 20, errorText: $amountError)
                }
                
                Button {
                    if ticker.isEmpty {
                        tickerError = "Please enter ticker"
                    }
                    if companyName.isEmpty {
                        companyNameError = "Please enter company name"
                    }
                    if let amountValue = Double(amount), amountValue == 0 {
                        amountError = "Please enter amount > 0"
                    } else if Double(amount) == nil {
                        amountError = "Please enter some amount"
                    }
                    
                    if let amountValue = Double(amount), amountValue > 0, !ticker.isEmpty, !companyName.isEmpty {
                        mainViewModel.addManualDividend(ticker: ticker, companyName: companyName, amount: amountValue)
                        dismiss()
                    }
                } label: {
                    Text("Add Dividend")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.PINK_COLOR)
                        .cornerRadius(16)
                        .shadow(color: AppColors.PINK_COLOR.opacity(0.3), radius: 20)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}

//MARK: Edit Dividend Bottom Sheet
struct EditDividendBottomSheet: View {
    @ObservedObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var companyName: String
    @State private var companyNameError: String?
    
    @State private var amount: String
    @State private var amountError: String?
    
    let item: DividendItem
    
    init(item: DividendItem, mainViewModel: MainViewModel) {
        self.item = item
        self.mainViewModel = mainViewModel
        _companyName = State(initialValue: item.name)
        _amount = State(initialValue: String(format: "%.2f", item.amount))
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.04).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Edit Dividend")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    DividendBottomSheetTextField(label: "COMPANY NAME", placeholder: "", text: $companyName, charLimit: 100, errorText: $companyNameError)
                    DividendBottomSheetTextField(label: "DIVIDEND AMOUNT (₹)", placeholder: "", text: $amount, keyboardType: .decimalPad, charLimit: 20, errorText: $amountError)
                }
                
                VStack(spacing: 12) {
                    Button {
                        if companyName.isEmpty {
                            companyNameError = "Please enter company name"
                        }
                        if let amountValue = Double(amount), amountValue == 0 {
                            amountError = "Please enter amount > 0"
                        } else if Double(amount) == nil {
                            amountError = "Please enter some amount"
                        }
                        if let amountValue = Double(amount), amountValue > 0, !companyName.isEmpty {
                            mainViewModel.updateManualDividend(ticker: item.ticker, companyName: companyName, amount: amountValue)
                            dismiss()
                        }
                    } label: {
                        Text("Update Dividend")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.PINK_COLOR)
                            .cornerRadius(16)
                            .shadow(color: AppColors.PINK_COLOR.opacity(0.3), radius: 20)
                    }
                    
                    Button {
                        mainViewModel.deleteManualDividend(ticker: item.ticker)
                        dismiss()
                    } label: {
                        Text("DELETE ENTRY")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(height: 56)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}

//MARK: Logout bottom sheet
struct LogoutBottomSheet: View {
    @Environment(\.dismiss) var dismiss
    let handleUserLogout: () -> Void
    
    var body: some View {
        ZStack {
            Color(white: 0.07).ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Logout")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Are you sure you want to log out?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Button {
                    handleUserLogout()
                    dismiss()
                } label: {
                    Text("Logout")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.PINK_COLOR)
                        .cornerRadius(16)
                        .shadow(color: AppColors.PINK_COLOR.opacity(0.1), radius: 15)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}

//MARK: Shimmer View Helper
struct ShimmerRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(ShimmerOverlay(cornerRadius: 12, isAnimating: $isAnimating))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 16)
                    .overlay(ShimmerOverlay(cornerRadius: 4, isAnimating: $isAnimating))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 12)
                    .overlay(ShimmerOverlay(cornerRadius: 4, isAnimating: $isAnimating))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 2)
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct ShimmerOverlay: View {
    let cornerRadius: CGFloat
    @Binding var isAnimating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        }
    }
}

//MARK: Preview
#Preview {
    MainView(viewModel: MainViewModel(token: "abcd"))
}

import SwiftUI
import Charts

// MARK: - Presentation Shell

struct BusStatsPresentationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentSlide = 0
    private let totalSlides = 10

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentSlide) {
                Slide01_Title().tag(0)
                Slide02_Problem().tag(1)
                Slide03_TrendChart().tag(2)
                Slide04_YearOverYear().tag(3)
                Slide05_Projection().tag(4)
                Slide06_CostSavings().tag(5)
                Slide07_Communication().tag(6)
                Slide08_TrustSafety().tag(7)
                Slide09_BroaderImpact().tag(8)
                Slide10_Summary().tag(9)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Bottom HUD
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Dot indicators
                    HStack(spacing: 6) {
                        ForEach(0..<totalSlides, id: \.self) { i in
                            Circle()
                                .fill(i == currentSlide ? Color.white : Color.white.opacity(0.3))
                                .frame(width: i == currentSlide ? 8 : 5, height: i == currentSlide ? 8 : 5)
                                .animation(.spring(response: 0.3), value: currentSlide)
                        }
                    }

                    Spacer()

                    Text("\(currentSlide + 1)/\(totalSlides)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .padding(.top, 12)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }
}

// MARK: - Slide 1: Title

private struct Slide01_Title: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A0533"), Color(hex: "4A1A6B"), Color(hex: "8E44AD")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 350, height: 350)
                .offset(x: 140, y: -180)
            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 250, height: 250)
                .offset(x: -130, y: 200)

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 32)

                // Title
                Text("MagicBusRoute")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("School Bus Intelligence Platform")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 8)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 1.5)
                    .padding(.vertical, 24)

                // District tag
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(hex: "F5A623"))
                    Text("Fulton County Schools  ·  Atlanta, GA")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("2024 – 2026 Impact Analysis")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 6)

                Spacer()
                Spacer()

                // Swipe hint
                HStack(spacing: 6) {
                    Image(systemName: "hand.point.right")
                        .font(.system(size: 12))
                    Text("Swipe to explore")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.4))
                .padding(.bottom, 80)
            }
        }
    }
}

// MARK: - Slide 2: The Problem

private struct Slide02_Problem: View {
    var body: some View {
        ZStack {
            Color(hex: "0D0D1A").ignoresSafeArea()

            // Red glow
            Circle()
                .fill(Color(hex: "E74C3C").opacity(0.15))
                .frame(width: 400, height: 400)
                .offset(y: -60)
                .blur(radius: 80)

            VStack(spacing: 0) {
                Spacer()

                Text("THE PROBLEM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "E74C3C"))
                    .tracking(3)
                    .padding(.bottom, 24)

                // Big stat
                VStack(spacing: 4) {
                    Text("1,450")
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("students missed their bus")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                    Text("every single school day at peak (Aug 2024)")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 4)
                }
                .padding(.bottom, 40)

                // Sub-stats row
                HStack(spacing: 1) {
                    problemStat(value: "~90K", label: "Total\nStudents", color: Color(hex: "F5A623"))
                    Divider().background(Color.white.opacity(0.1)).frame(height: 50)
                    problemStat(value: "1.6%", label: "Daily\nNo-Show Rate", color: Color(hex: "E74C3C"))
                    Divider().background(Color.white.opacity(0.1)).frame(height: 50)
                    problemStat(value: "180", label: "School\nDays/Year", color: Color(hex: "8E44AD"))
                }
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Annual total
                VStack(spacing: 6) {
                    Text("That's over")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Text("261,000")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "E74C3C"))
                    Text("missed bus rides per year")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()
                Spacer()
            }
        }
    }

    private func problemStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Slide 3: Trend Chart

private struct Slide03_TrendChart: View {
    private let data = BusNoShowDataPoint.fultonCountyMock()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "0D2137")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Heading
                VStack(alignment: .leading, spacing: 6) {
                    Text("IS IT GETTING BETTER?")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "2F80ED"))
                        .tracking(2)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Improving")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "2ECC71"))
                            Text("YES")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "2ECC71"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(hex: "2ECC71").opacity(0.15))
                        .cornerRadius(20)
                    }

                    Text("Average daily no-shows dropping year over year")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Chart
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Month", point.month),
                            y: .value("No-Shows", point.avgDailyNoShows)
                        )
                        .foregroundStyle(by: .value("Year", "\(point.year)"))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        AreaMark(
                            x: .value("Month", point.month),
                            yStart: .value("Base", 400),
                            yEnd: .value("No-Shows", point.avgDailyNoShows)
                        )
                        .foregroundStyle(by: .value("Year", "\(point.year)"))
                        .opacity(0.12)
                    }
                }
                .chartForegroundStyleScale([
                    "2024": Color(hex: "E74C3C"),
                    "2025": Color(hex: "F5A623"),
                    "2026": Color(hex: "2ECC71")
                ])
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 3)) { v in
                        if let d = v.as(Date.self) {
                            AxisValueLabel {
                                Text(mmYY(d))
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.08))
                        if let val = v.as(Int.self) {
                            AxisValueLabel {
                                Text("\(val)")
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                // Legend row
                HStack(spacing: 20) {
                    Spacer()
                    legendItem(color: "E74C3C", label: "2024")
                    legendItem(color: "F5A623", label: "2025")
                    legendItem(color: "2ECC71", label: "2026")
                    Spacer()
                }
                .padding(.bottom, 32)

                // Note
                Text("* School months only (Aug–May). Summer excluded.")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 80)

                Spacer()
            }
        }
    }

    private func legendItem(color: String, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: color))
                .frame(width: 20, height: 3)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func mmYY(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM'yy"; return f.string(from: date)
    }
}

// MARK: - Slide 4: Year-over-Year Breakdown

private struct Slide04_YearOverYear: View {
    private let years: [(year: String, avg: Int, change: Int?, label: String)] = [
        ("2024", 958,  nil,  "Baseline year"),
        ("2025", 857,  -11,  "Improving"),
        ("2026", 767,  -11,  "On track"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "112240")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("YEAR-OVER-YEAR")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2F80ED"))
                    .tracking(2)
                    .padding(.bottom, 8)

                Text("Avg Daily No-Shows")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 32)

                // Bar comparison
                VStack(spacing: 20) {
                    ForEach(years, id: \.year) { row in
                        yoyRow(row)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

                // Arrow flow
                HStack(spacing: 0) {
                    flowBox(value: "958", label: "2024 Avg", color: "E74C3C")
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 8)
                    flowBox(value: "857", label: "2025 Avg", color: "F5A623")
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 8)
                    flowBox(value: "767", label: "2026 Avg*", color: "2ECC71")
                }
                .padding(.horizontal, 24)

                Text("* Jan–Apr 2026 only")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 10)

                Spacer()
                Spacer()
            }
        }
    }

    private func yoyRow(_ row: (year: String, avg: Int, change: Int?, label: String)) -> some View {
        let maxAvg = 958.0
        let fraction = Double(row.avg) / maxAvg

        return VStack(spacing: 6) {
            HStack {
                Text(row.year)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 44, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 28)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(row.year))
                            .frame(width: geo.size.width * fraction, height: 28)

                        Text("\(row.avg)/day")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                    }
                }
                .frame(height: 28)

                if let change = row.change {
                    Text("\(change)%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(change < 0 ? Color(hex: "2ECC71") : Color(hex: "E74C3C"))
                        .frame(width: 46, alignment: .trailing)
                } else {
                    Text("—")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 46, alignment: .trailing)
                }
            }

            HStack {
                Spacer().frame(width: 44)
                Text(row.label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
            }
        }
    }

    private func barColor(_ year: String) -> Color {
        switch year {
        case "2024": return Color(hex: "E74C3C")
        case "2025": return Color(hex: "F5A623")
        default:     return Color(hex: "2ECC71")
        }
    }

    private func flowBox(value: String, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Slide 5: Projection (With vs Without App)

private struct Slide05_Projection: View {

    struct ProjectionPoint: Identifiable {
        let id = UUID()
        let year: Int
        let withApp: Int
        let withoutApp: Int
    }

    private let points: [ProjectionPoint] = [
        .init(year: 2024, withApp: 958,  withoutApp: 958),
        .init(year: 2025, withApp: 857,  withoutApp: 857),
        .init(year: 2026, withApp: 640,  withoutApp: 700),
        .init(year: 2027, withApp: 520,  withoutApp: 580),
        .init(year: 2028, withApp: 390,  withoutApp: 522),
        .init(year: 2029, withApp: 280,  withoutApp: 470),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "050D1F"), Color(hex: "0A1628")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("WITH MAGICBUSROUTE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "8E44AD"))
                        .tracking(2)

                    Text("2026 – 2029\nProjected Impact")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("App-accelerated improvement vs. organic trend")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                Chart {
                    ForEach(points) { p in
                        LineMark(
                            x: .value("Year", p.year),
                            y: .value("No-Shows", p.withoutApp)
                        )
                        .foregroundStyle(Color(hex: "E74C3C"))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))

                        LineMark(
                            x: .value("Year", p.year),
                            y: .value("No-Shows", p.withApp)
                        )
                        .foregroundStyle(Color(hex: "8E44AD"))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        AreaMark(
                            x: .value("Year", p.year),
                            yStart: .value("WithApp", p.withApp),
                            yEnd: .value("WithoutApp", p.withoutApp)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "8E44AD").opacity(0.25), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Year", p.year),
                            y: .value("No-Shows", p.withApp)
                        )
                        .foregroundStyle(Color(hex: "8E44AD"))
                        .symbolSize(32)
                    }

                    RuleMark(x: .value("Now", 2026))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top) {
                            Text("NOW")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                }
                .chartXAxis {
                    AxisMarks(values: [2024, 2025, 2026, 2027, 2028, 2029]) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.07))
                        if let year = v.as(Int.self) {
                            AxisValueLabel {
                                Text("\(year)")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.07))
                        if let val = v.as(Int.self) {
                            AxisValueLabel {
                                Text("\(val)")
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                HStack(spacing: 20) {
                    Spacer()
                    HStack(spacing: 6) {
                        Rectangle().fill(Color(hex: "8E44AD"))
                            .frame(width: 20, height: 3).cornerRadius(2)
                        Text("With MagicBusRoute")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    HStack(spacing: 6) {
                        Rectangle().fill(Color(hex: "E74C3C"))
                            .frame(width: 20, height: 2)
                        Text("Without App")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.bottom, 20)

                HStack(spacing: 0) {
                    projStat(value: "280", label: "Daily avg\nby 2029",          sub: "vs 640 today",       color: "8E44AD")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 50)
                    projStat(value: "190", label: "More students\nto school/day", sub: "vs no-app path",    color: "2ECC71")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 50)
                    projStat(value: "34K", label: "School days\nrecovered/year",  sub: "in one district",   color: "F5A623")
                }
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 80)

                Spacer()
            }
        }
    }

    private func projStat(value: String, label: String, sub: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Text(sub)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Slide 6: Cost Savings

private struct Slide06_CostSavings: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A2218"), Color(hex: "0D3826")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "2ECC71").opacity(0.1))
                .frame(width: 380, height: 380)
                .offset(x: 140, y: -160)
                .blur(radius: 60)

            VStack(spacing: 0) {
                Spacer()

                Text("COST IMPACT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2ECC71"))
                    .tracking(2)
                    .padding(.bottom, 8)

                Text("What No-Shows Really Cost")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)

                // Cost breakdown
                VStack(spacing: 12) {
                    costRow(icon: "phone.fill",       label: "Parent calls + staff handling",  value: "$3.50",  sub: "per incident")
                    costRow(icon: "clock.fill",        label: "Driver wait time (avg 12 min)", value: "$6.00",  sub: "per incident")
                    costRow(icon: "arrow.triangle.2.circlepath", label: "Route rescheduling overhead", value: "$1.50", sub: "per incident")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Total per incident
                HStack {
                    Text("Total cost per missed bus")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("~$11 / incident")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "F5A623"))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)

                // Big annual number
                VStack(spacing: 6) {
                    Text("$2.3M+")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "E74C3C"))
                    Text("estimated annual cost to district (2024)")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 24)

                // Savings potential
                HStack(spacing: 12) {
                    savingsBadge(pct: "18%", label: "Already\nSaved", color: "2ECC71")
                    savingsBadge(pct: "$414K", label: "Estimated\nSavings/yr", color: "2ECC71")
                    savingsBadge(pct: "40%", label: "Target\nReduction", color: "F5A623")
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
    }

    private func costRow(icon: String, label: String, value: String, sub: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "2ECC71").opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "2ECC71"))
            }
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    private func savingsBadge(pct: String, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(pct)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: color).opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Slide 7: Communication

private struct Slide07_Communication: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "051025"), Color(hex: "0A1E40")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("COMMUNICATION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2F80ED"))
                    .tracking(2)
                    .padding(.bottom, 8)

                Text("Everyone Stays\nIn the Loop")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)

                // Triangle diagram
                VStack(spacing: 0) {
                    commNode(icon: "person.fill", label: "Parent", color: "8E44AD", detail: "Real-time bus location\n& ETA alerts")

                    HStack(spacing: 0) {
                        connectorLine()
                        Spacer()
                        connectorLine()
                    }
                    .padding(.horizontal, 80)
                    .padding(.vertical, -4)

                    HStack(spacing: 40) {
                        commNode(icon: "bus.fill", label: "Driver", color: "2F80ED", detail: "Instant dispatch\nmessaging")
                        commNode(icon: "antenna.radiowaves.left.and.right", label: "Dispatch", color: "2ECC71", detail: "Live route\nmonitoring")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 28)

                // Feature bullets
                VStack(spacing: 10) {
                    commFeature(icon: "bell.fill",          color: "F5A623", text: "Push alerts when bus is 5 minutes away")
                    commFeature(icon: "exclamationmark.bubble.fill", color: "E74C3C", text: "Instant incident notifications to all parties")
                    commFeature(icon: "map.fill",           color: "2F80ED", text: "Live GPS route visible to parents at any time")
                    commFeature(icon: "checkmark.message.fill", color: "2ECC71", text: "Student pickup confirmation sent to parent")
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
    }

    private func commNode(icon: String, label: String, color: String, detail: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color(hex: color).opacity(0.2)).frame(width: 64, height: 64)
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(Color(hex: color))
            }
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(detail)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private func connectorLine() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 60, height: 1.5)
    }

    private func commFeature(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: color))
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Slide 8: Trust & Safety

private struct Slide08_TrustSafety: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A0A2E"), Color(hex: "2D1550")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "8E44AD").opacity(0.12))
                .frame(width: 400, height: 400)
                .offset(y: 100)
                .blur(radius: 80)

            VStack(spacing: 0) {
                Spacer()

                Text("TRUST & SAFETY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "8E44AD"))
                    .tracking(2)
                    .padding(.bottom, 8)

                Text("Parents Trust\nWhat They Can See")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    trustCard(icon: "location.fill",       title: "Live GPS",           body: "Bus location updated every 30 seconds for parents",         color: "2F80ED")
                    trustCard(icon: "shield.checkered",    title: "Pickup Verified",    body: "Photo confirmation when student boards the bus",            color: "2ECC71")
                    trustCard(icon: "exclamationmark.triangle", title: "Incident Alerts", body: "Parents notified instantly of any delays or issues",     color: "F5A623")
                    trustCard(icon: "person.badge.clock",  title: "Driver Accountability", body: "All route events timestamped and logged",               color: "8E44AD")
                    trustCard(icon: "eye.fill",            title: "Admin Oversight",    body: "Full real-time dashboard for school administrators",        color: "E74C3C")
                    trustCard(icon: "lock.shield.fill",    title: "Data Security",      body: "Biometric lock, cert pinning, session timeout built-in",   color: "2F80ED")
                }
                .padding(.horizontal, 20)

                Spacer()
                Spacer()
            }
        }
    }

    private func trustCard(icon: String, title: String, body: String, color: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: color))
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(body)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
    }
}

// MARK: - Slide 9: Broader Impact

private struct Slide09_BroaderImpact: View {
    private let impacts: [(icon: String, title: String, body: String, color: String)] = [
        ("graduationcap.fill",     "School Attendance",    "Fewer missed buses = fewer missed school days. Directly improves district attendance rates.",          "F5A623"),
        ("chart.bar.doc.horizontal", "Admin Insights",    "Admins gain trend data to optimize routes, reduce fleet size, and allocate resources smarter.",        "2F80ED"),
        ("figure.walk.to.bus",     "Driver Accountability","Route logs hold drivers accountable for timing, stops, and student pickups.",                          "8E44AD"),
        ("heart.fill",             "Parent Peace of Mind", "Reduced anxiety for parents who previously had no visibility into where the bus was.",                  "E74C3C"),
        ("leaf.fill",              "Fuel Efficiency",      "Optimized routes and fewer re-runs reduce fuel consumption and carbon footprint.",                      "2ECC71"),
        ("building.columns.fill",  "District Reputation",  "Transparent, reliable transportation builds community trust in the school system.",                    "F5A623"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A0E00"), Color(hex: "2D1900")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "F5A623").opacity(0.08))
                .frame(width: 350, height: 350)
                .offset(x: 130, y: -120)
                .blur(radius: 60)

            VStack(spacing: 0) {
                Spacer()

                Text("BROADER IMPACT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "F5A623"))
                    .tracking(2)
                    .padding(.bottom, 8)

                Text("Beyond the Bus Stop")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 28)

                VStack(spacing: 10) {
                    ForEach(impacts, id: \.title) { item in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: item.color).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: item.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: item.color))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(item.body)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Slide 10: Summary

private struct Slide10_Summary: View {
    private let pillars: [(icon: String, label: String, color: String)] = [
        ("dollarsign.circle.fill",       "Cost Reduction",     "2ECC71"),
        ("bubble.left.and.bubble.right.fill", "Communication", "2F80ED"),
        ("shield.checkered",             "Trust & Safety",     "8E44AD"),
        ("graduationcap.fill",           "Attendance",         "F5A623"),
        ("chart.xyaxis.line",            "Data & Insights",    "E74C3C"),
        ("leaf.fill",                    "Sustainability",     "2ECC71"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A0533"), Color(hex: "4A1A6B"), Color(hex: "8E44AD")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 350, height: 350)
                .offset(x: -140, y: -160)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "bus.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 16)

                Text("MagicBusRoute")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("improves 6 areas that matter")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)
                    .padding(.bottom, 32)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(pillars, id: \.label) { p in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: p.color).opacity(0.2))
                                    .frame(width: 52, height: 52)
                                Image(systemName: p.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: p.color))
                            }
                            Text(p.label)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Closing stat
                VStack(spacing: 4) {
                    Text("640 fewer students stranded daily")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                    Text("and improving every year.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    BusStatsPresentationView()
}

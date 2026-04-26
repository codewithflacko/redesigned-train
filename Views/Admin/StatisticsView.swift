import SwiftUI
import Charts

// MARK: - Data Models

struct BusNoShowDataPoint: Identifiable {
    let id = UUID()
    let month: Date
    let avgDailyNoShows: Int
    let year: Int

    var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: month)
    }
}

struct StatHighlight {
    let value: String
    let label: String
    let detail: String
    let icon: String
    let color: Color
}

// MARK: - Statistics View

struct StatisticsView: View {
    @State private var selectedYear: Int? = nil  // nil = show all

    private let allData: [BusNoShowDataPoint] = BusNoShowDataPoint.fultonCountyMock()

    private var filteredData: [BusNoShowDataPoint] {
        guard let year = selectedYear else { return allData }
        return allData.filter { $0.year == year }
    }

    private var years: [Int] { [2024, 2025, 2026] }

    private var highlights: [StatHighlight] {
        let peakPoint = allData.max(by: { $0.avgDailyNoShows < $1.avgDailyNoShows })
        let latestPoint = allData.last
        let avg2024 = average(for: 2024)
        let avg2025 = average(for: 2025)
        let improvement = avg2024 > 0 ? Int(((avg2024 - avg2025) / avg2024) * 100) : 0

        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        let peakLabel = peakPoint.map { f.string(from: $0.month) } ?? "—"

        return [
            StatHighlight(
                value: "\(peakPoint?.avgDailyNoShows ?? 0)",
                label: "Peak Daily No-Shows",
                detail: peakLabel,
                icon: "exclamationmark.triangle.fill",
                color: Color(hex: "E74C3C")
            ),
            StatHighlight(
                value: "\(latestPoint?.avgDailyNoShows ?? 0)",
                label: "Current Daily Avg",
                detail: "Apr 2026",
                icon: "person.fill.xmark",
                color: Color(hex: "2F80ED")
            ),
            StatHighlight(
                value: "\(improvement)%",
                label: "YoY Improvement",
                detail: "2024 → 2025",
                icon: "arrow.down.right.circle.fill",
                color: Color(hex: "2ECC71")
            ),
            StatHighlight(
                value: totalNoShows(),
                label: "Total No-Shows",
                detail: "2024 – 2026",
                icon: "sum",
                color: Color(hex: "8E44AD")
            )
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            districtHeader
            highlightGrid
            yearFilter
            chartCard
            insightsCard
            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - District Header

    private var districtHeader: some View {
        VStack(spacing: 4) {
            Text("FULTON COUNTY SCHOOLS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.5)
            Text("Bus No-Show Statistics")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "1A1A2E"))
            Text("Atlanta, GA  ·  2024 – 2026  ·  ~90,000 Students")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
    }

    // MARK: - Highlight Grid

    private var highlightGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(highlights, id: \.label) { h in
                highlightCard(h)
            }
        }
    }

    private func highlightCard(_ h: StatHighlight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: h.icon)
                    .font(.system(size: 16))
                    .foregroundColor(h.color)
                Spacer()
            }
            Text(h.value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(h.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(h.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A2E"))
                Text(h.detail)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 5, y: 3)
        )
    }

    // MARK: - Year Filter

    private var yearFilter: some View {
        HStack(spacing: 8) {
            filterChip(label: "All Years", year: nil)
            ForEach(years, id: \.self) { year in
                filterChip(label: "\(year)", year: year)
            }
            Spacer()
        }
    }

    private func filterChip(label: String, year: Int?) -> some View {
        let active = selectedYear == year
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedYear = year }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(active ? .white : Color(hex: "8E44AD"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(active ? Color(hex: "8E44AD") : Color(hex: "8E44AD").opacity(0.1))
                )
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AVERAGE DAILY NO-SHOWS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    Text("Students who missed the bus")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                legendDots
            }

            Chart {
                ForEach(filteredData) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("No-Shows", point.avgDailyNoShows)
                    )
                    .foregroundStyle(by: .value("Year", "\(point.year)"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("Base", 0),
                        yEnd: .value("No-Shows", point.avgDailyNoShows)
                    )
                    .foregroundStyle(by: .value("Year", "\(point.year)"))
                    .opacity(0.07)

                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("No-Shows", point.avgDailyNoShows)
                    )
                    .foregroundStyle(by: .value("Year", "\(point.year)"))
                    .symbolSize(28)
                }
            }
            .chartForegroundStyleScale([
                "2024": Color(hex: "E74C3C"),
                "2025": Color(hex: "F5A623"),
                "2026": Color(hex: "2ECC71")
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(shortMonthYear(date))
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }

    private var legendDots: some View {
        HStack(spacing: 10) {
            ForEach([("2024", "E74C3C"), ("2025", "F5A623"), ("2026", "2ECC71")], id: \.0) { year, hex in
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: hex)).frame(width: 8, height: 8)
                    Text(year)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func shortMonthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM'yy"
        return f.string(from: date)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "F5A623"))
                Text("KEY INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
            }

            insightRow(icon: "calendar.badge.exclamationmark",
                       color: Color(hex: "E74C3C"),
                       text: "August peaks annually as students return to school — average 1,400+ daily no-shows during the first week.")

            insightRow(icon: "snowflake",
                       color: Color(hex: "2F80ED"),
                       text: "January–February see weather-related spikes, adding ~200 no-shows per day compared to fall months.")

            insightRow(icon: "arrow.down.circle.fill",
                       color: Color(hex: "2ECC71"),
                       text: "Year-over-year improvement of ~18% from 2024 to 2025, driven by better route notifications.")

            insightRow(icon: "exclamationmark.circle",
                       color: Color(hex: "8E44AD"),
                       text: "~640 students miss the bus daily as of April 2026 — down from a peak of 1,450 in August 2024.")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        )
    }

    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color(hex: "1A1A2E"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helpers

    private func average(for year: Int) -> Double {
        let pts = allData.filter { $0.year == year }
        guard !pts.isEmpty else { return 0 }
        return Double(pts.map { $0.avgDailyNoShows }.reduce(0, +)) / Double(pts.count)
    }

    private func totalNoShows() -> String {
        // Multiply avg daily × ~22 school days per month
        let total = allData.map { $0.avgDailyNoShows * 22 }.reduce(0, +)
        if total >= 1_000_000 {
            return String(format: "%.1fM", Double(total) / 1_000_000)
        } else {
            return String(format: "%.0fK", Double(total) / 1_000)
        }
    }
}

// MARK: - Mock Data

extension BusNoShowDataPoint {
    static func fultonCountyMock() -> [BusNoShowDataPoint] {
        let cal = Calendar.current
        func date(year: Int, month: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        }

        // School months only: Jan-May + Aug-Dec
        // Realistic avg daily no-shows for Fulton County (~90k students)
        return [
            // 2024
            .init(month: date(year: 2024, month: 1),  avgDailyNoShows: 1_240, year: 2024),
            .init(month: date(year: 2024, month: 2),  avgDailyNoShows: 980,   year: 2024),
            .init(month: date(year: 2024, month: 3),  avgDailyNoShows: 820,   year: 2024),
            .init(month: date(year: 2024, month: 4),  avgDailyNoShows: 760,   year: 2024),
            .init(month: date(year: 2024, month: 5),  avgDailyNoShows: 690,   year: 2024),
            .init(month: date(year: 2024, month: 8),  avgDailyNoShows: 1_450, year: 2024),
            .init(month: date(year: 2024, month: 9),  avgDailyNoShows: 1_180, year: 2024),
            .init(month: date(year: 2024, month: 10), avgDailyNoShows: 890,   year: 2024),
            .init(month: date(year: 2024, month: 11), avgDailyNoShows: 820,   year: 2024),
            .init(month: date(year: 2024, month: 12), avgDailyNoShows: 750,   year: 2024),
            // 2025
            .init(month: date(year: 2025, month: 1),  avgDailyNoShows: 1_100, year: 2025),
            .init(month: date(year: 2025, month: 2),  avgDailyNoShows: 850,   year: 2025),
            .init(month: date(year: 2025, month: 3),  avgDailyNoShows: 720,   year: 2025),
            .init(month: date(year: 2025, month: 4),  avgDailyNoShows: 680,   year: 2025),
            .init(month: date(year: 2025, month: 5),  avgDailyNoShows: 620,   year: 2025),
            .init(month: date(year: 2025, month: 8),  avgDailyNoShows: 1_320, year: 2025),
            .init(month: date(year: 2025, month: 9),  avgDailyNoShows: 1_050, year: 2025),
            .init(month: date(year: 2025, month: 10), avgDailyNoShows: 810,   year: 2025),
            .init(month: date(year: 2025, month: 11), avgDailyNoShows: 740,   year: 2025),
            .init(month: date(year: 2025, month: 12), avgDailyNoShows: 680,   year: 2025),
            // 2026
            .init(month: date(year: 2026, month: 1),  avgDailyNoShows: 980,   year: 2026),
            .init(month: date(year: 2026, month: 2),  avgDailyNoShows: 760,   year: 2026),
            .init(month: date(year: 2026, month: 3),  avgDailyNoShows: 690,   year: 2026),
            .init(month: date(year: 2026, month: 4),  avgDailyNoShows: 640,   year: 2026),
        ]
    }
}

#Preview {
    ScrollView {
        StatisticsView()
            .padding(.top, 16)
    }
    .background(Color(hex: "F5F0FF"))
}

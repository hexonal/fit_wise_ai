//
//  HealthStatsView.swift
//  fit_wise_ai
//
//  Created by shizeying on 2025/8/13.
//

import SwiftUI

struct HealthStatsView: View {
    let healthData: HealthData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细数据")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                StatRow(
                    icon: "heart.fill",
                    title: "心率",
                    value: healthData.formattedHeartRate,
                    unit: "bpm",
                    color: .red
                )
                
                StatRow(
                    icon: "figure.walk",
                    title: "步行距离",
                    value: healthData.formattedDistance,
                    unit: "km",
                    color: .blue
                )
                
                StatRow(
                    icon: "clock.fill",
                    title: "活动时长",
                    value: healthData.formattedWorkoutTime,
                    unit: "",
                    color: .green
                )
                
                if let heartRate = healthData.heartRate {
                    let zone = getHeartRateZone(heartRate)
                    StatRow(
                        icon: "waveform.path.ecg",
                        title: "心率区间",
                        value: zone.name,
                        unit: "",
                        color: zone.color
                    )
                }
            }
        }
    }
    
    private func getHeartRateZone(_ heartRate: Double) -> (name: String, color: Color) {
        switch heartRate {
        case 0..<60:
            return ("静息", .gray)
        case 60..<100:
            return ("正常", .green)
        case 100..<120:
            return ("轻度活跃", .yellow)
        case 120..<150:
            return ("中度活跃", .orange)
        default:
            return ("高强度", .red)
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HealthStatsView(
        healthData: HealthData(
            steps: 8500,
            heartRate: 72,
            activeEnergyBurned: 320,
            workoutTime: 2400,
            distanceWalkingRunning: 5200
        )
    )
}
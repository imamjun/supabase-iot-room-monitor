import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data_model.dart';
import '../services/auth_service.dart';
import '../services/sensor_service.dart';
import 'login_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final SensorService sensorService = SensorService();
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Real-time & Grafik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<SensorData>>(
        stream: sensorService.getRealtimeSensorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data sensor.'));
          }

          // Data dari stream (terbaru ada di indeks 0)
          final sensorList = snapshot.data!;
          final latestData = sensorList.first;

          // Urutkan data secara ascending (lama ke baru) khusus untuk plotting grafik dari kiri ke kanan
          final chartData = List<SensorData>.from(sensorList.reversed);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan Nilai Terbaru (Cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Suhu',
                        value: '${latestData.temperature.toStringAsFixed(1)} °C',
                        icon: Icons.thermostat,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Kelembapan',
                        value: '${latestData.humidity.toStringAsFixed(1)} %',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section Grafik Suhu
                const Text(
                  'Grafik Riwayat Suhu (°C)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(
                    data: chartData,
                    isTemperature: true,
                    lineColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),

                // Section Grafik Kelembapan
                const Text(
                  'Grafik Riwayat Kelembapan (%)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(
                    data: chartData,
                    isTemperature: false,
                    lineColor: Colors.blue,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget Card Ringkasan Metric
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Component Pembentuk Grafik Real-time
  Widget _buildLineChart({
    required List<SensorData> data,
    required bool isTemperature,
    required Color lineColor,
  }) {
    final double minY = isTemperature ? 20 : 30;
    final double maxY = isTemperature ? 30 : 45;
    final double xInterval = data.length > 1 ? (data.length - 1) / 4 : 1;

    // Memetakan list data sensor ke koordinat FlSpot (X = Indeks waktu, Y = Nilai Sensor)
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double yVal = isTemperature ? data[i].temperature : data[i].humidity;
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: xInterval > 0 ? xInterval : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox();
                    }

                    final date = data[index].createdAt;
                    final timeLabel =
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        timeLabel,
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColor.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
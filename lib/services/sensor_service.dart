import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_data_model.dart';

class SensorService {
  final SupabaseClient _client = Supabase.instance.client;

  // Mengambil 15 data terakhir untuk grafik
  Stream<List<SensorData>> getRealtimeSensorData() {
    return _client
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(15) 
        .map((dataList) =>
            dataList.map((json) => SensorData.fromJson(json)).toList());
  }
}
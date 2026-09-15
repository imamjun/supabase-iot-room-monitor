#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h> // Pastikan library "ArduinoJson" oleh Benoit Blanchon sudah diinstall
#include <DHT.h>

// Konfigurasi WiFi
const char* ssid = "poco";
const char* password = "pocoloco";

// Konfigurasi Supabase
const char* supabase_url = "https://caccgejhcryplnmbxgtv.supabase.co";
const char* supabase_publishable_key = "sb_publishable_jPjEYcCbszcJn20vOjMBeQ_4ACHe9Mt";

// Kredensial User Supabase Auth untuk ESP32
const char* auth_email = "esp32@device.com";
const char* auth_password = "PasswordESP32123";

// Variabel untuk menyimpan JWT Access Token
String accessToken = "";

// Konfigurasi DHT11
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Fungsi untuk Login dan mendapatkan Access Token
bool loginToSupabase() {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String authUrl = String(supabase_url) + "/auth/v1/token?grant_type=password";

  http.begin(authUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", supabase_publishable_key);

  String payload = "{\"email\":\"" + String(auth_email) + "\",\"password\":\"" + String(auth_password) + "\"}";

  int httpCode = http.POST(payload);

  if (httpCode == 200) {
    String response = http.getString();
    
    // Parse JSON untuk mengambil access_token
    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, response);

    if (!error) {
      accessToken = doc["access_token"].as<String>();
      Serial.println(" Login Supabase Berhasil!");
      http.end();
      return true;
    }
  }

  Serial.printf(" Login Gagal. Status Code: %d\n", httpCode);
  http.end();
  return false;
}

// Fungsi untuk Mengirim Data Sensor
void sendSensorData(float temp, float hum) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String dbUrl = String(supabase_url) + "/rest/v1/sensor_data";

  http.begin(dbUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", supabase_publishable_key);
  // Gunakan Access Token yang didapat dari Login
  http.addHeader("Authorization", "Bearer " + accessToken);

  String jsonPayload = "{\"temperature\":" + String(temp) + ", \"humidity\":" + String(hum) + "}";

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode == 201) {
    Serial.println(" Data berhasil dikirim (Authenticated)!");
  } else if (httpResponseCode == 401) {
    Serial.println(" Token kadaluarsa atau tidak valid. Mencoba login ulang...");
    if (loginToSupabase()) {
      sendSensorData(temp, hum); // Coba kirim ulang setelah re-login
    }
  } else {
    Serial.printf(" Gagal mengirim data. Kode respon: %d\n", httpResponseCode);
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Menghubungkan ke WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Terhubung!");

  // Lakukan Login saat setup pertama kali
  loginToSupabase();
}

void loop() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println("Gagal membaca dari sensor DHT11!");
    delay(2000);
    return;
  }

  Serial.printf("Suhu: %.2f °C | Kelembapan: %.2f %%\n", t, h);

  // Jika token belum ada, coba login dulu
  if (accessToken == "") {
    loginToSupabase();
  }

  // Kirim data jika token sudah tersedia
  if (accessToken != "") {
    sendSensorData(t, h);
  }

  delay(10000);
}
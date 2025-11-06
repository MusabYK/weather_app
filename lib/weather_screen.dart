import 'dart:convert';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController dropDownController = TextEditingController();
  List<String> cities = ['Jalingo', 'Abuja', 'Lagos'];
  String city = "Jalingo";
  static final String _apiKey =
      dotenv.env['OPENWEATHER_API_KEY'] ?? 'API_KEY_NOT_FOUND';
  @override
  void initState() {
    super.initState();
    dropDownController.text = city;
  }

  // Get weather function
  Future<Map<String, dynamic>> getCurrentWeather() async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
      'q': city,
      'appid': _apiKey,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load weather (status ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final list = data['list'];
      if (list == null || list is! List || list.isEmpty) {
        throw Exception('Unexpected API response: missing forecast list');
      }

      return data;
    } catch (e) {
      // Preserve stack trace for callers
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // elevation: 5,
        title: const Text(
          "Weather App",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getCurrentWeather(),
        builder: (context, snapshot) {
          // print(snapshot);
          //print(snapshot.runtimeType);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load weather.'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final forecastData = snapshot.data!;
          final forecastList = forecastData['list'];
          if (forecastList is! List || forecastList.isEmpty) {
            return const Center(child: Text('No forecast data available.'));
          }

          final currentForecastData = forecastList[0] as Map<String, dynamic>;

          final tempK = (currentForecastData['main']['temp'] as num).toDouble();
          final temp = tempK - 273.15;

          final currentSky = (currentForecastData['weather'][0]['main'])
              .toString();
          final currentPressure = currentForecastData['main']['pressure']
              .toString();
          final currentHumidity = currentForecastData['main']['humidity']
              .toString();
          final currentWindSpeed = currentForecastData['wind']['speed']
              .toString();

          // calculate item count for hourly list (skip index 0 which is current)
          final available = (forecastList.length);
          final hourlyAvailable = available > 1 ? available - 1 : 0;
          final hourlyItemCount = hourlyAvailable >= 8 ? 8 : hourlyAvailable;

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: DropdownMenu<String>(
                    initialSelection: city,
                    controller: dropDownController,
                    // requestFocusOnTap is enabled/disabled by platforms when it is null.
                    // On mobile platforms, this is false by default. Setting this to true will
                    // trigger focus request on the text field and virtual keyboard will appear
                    // afterward. On desktop platforms however, this defaults to true.
                    requestFocusOnTap: true,
                    label: const Text('City'),
                    dropdownMenuEntries: cities.map<DropdownMenuEntry<String>>((
                      String item,
                    ) {
                      return DropdownMenuEntry<String>(
                        value: item,
                        label: item,
                        enabled: true,
                        style: MenuItemButton.styleFrom(
                          // foregroundColor: Colors.red,
                        ),
                      );
                    }).toList(),
                    onSelected: (String? item) {
                      if (item == null) return;
                      setState(() {
                        city = item;
                        dropDownController.text = item;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    // Header card
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      // this is just to increase the borderRadius
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      // used to clip the backdrop filter
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Text(
                                "${temp.toStringAsFixed(2)}° C",
                                style: const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                currentSky == "Clouds" || currentSky == "Rain"
                                    ? Icons.cloud
                                    : Icons.sunny,
                                size: 84,
                              ),
                              Text(currentSky),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Forecasts
                const Text(
                  "Forecast",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height:
                      120, //SizeBox is needed otherwise the ListVie.builder will take up the entire screen
                  child: hourlyItemCount == 0
                      ? const Center(
                          child: Text('No hourly forecast available'),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hourlyItemCount,
                          itemBuilder: (context, index) {
                            final hourlyForecast =
                                forecastList[index + 1] as Map<String, dynamic>;
                            final hourlySky =
                                (hourlyForecast['weather'][0]['main'])
                                    .toString();
                            final dateTime = DateTime.parse(
                              hourlyForecast['dt_txt'].toString(),
                            );
                            final hourlyTempK =
                                (hourlyForecast['main']['temp'] as num)
                                    .toDouble();
                            final hourlyTempC = hourlyTempK - 273.15;
                            return HourlyForecastItem(
                              icon: hourlySky == "Clouds" || hourlySky == "Rain"
                                  ? Icons.cloud
                                  : Icons.sunny,
                              time: DateFormat.j().format(dateTime),
                              temp: "${hourlyTempC.toStringAsFixed(1)}°C",
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Additional Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AdditionalWeatherInfo(
                      icon: Icons.cloudy_snowing,
                      weatherType: "Humidity",
                      value: currentHumidity,
                    ),
                    AdditionalWeatherInfo(
                      icon: Icons.wind_power,
                      weatherType: "Wind Speed",
                      value: currentWindSpeed,
                    ),
                    AdditionalWeatherInfo(
                      icon: Icons.ac_unit,
                      weatherType: "Pressure",
                      value: currentPressure,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HourlyForecastItem extends StatelessWidget {
  final IconData icon;
  final String time;
  final String temp;
  const HourlyForecastItem({
    super.key,
    required this.icon,
    required this.time,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          children: [
            Text(
              time,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Icon(icon, size: 44),
            Text(temp),
          ],
        ),
      ),
    );
  }
}

class AdditionalWeatherInfo extends StatelessWidget {
  final IconData icon;
  final String weatherType;
  final String value;
  const AdditionalWeatherInfo({
    super.key,
    required this.icon,
    required this.weatherType,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
      child: Column(
        children: [
          Icon(icon, size: 44),
          Text(weatherType),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

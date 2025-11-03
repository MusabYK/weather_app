import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/secret_key.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController dropDownController = TextEditingController();
  List<String> cities = ['Jalingo', 'Abuja', 'Lagos'];
  String city = "Jalingo";
  // Get weather function
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      var response = await http.get(
        Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$city,&APPID=$openWeatherApiKey",
        ),
      );
      // print('Response status: ${response.statusCode}');
      // print(response.statusCode.runtimeType);
      if (response.statusCode != 200) {
        throw "Unexpected error occurred";
      }
      return jsonDecode(response.body);
    } catch (e) {
      throw "Thrown  Error: ${e.toString()}";
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
      body: FutureBuilder(
        future: getCurrentWeather(),
        builder: (context, snapshot) {
          // print(snapshot);
          //print(snapshot.runtimeType);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final forecastData = snapshot.data!;
          final currentForecastData = forecastData["list"][0];
          final temp = currentForecastData["main"]["temp"] - 273.15;
          final currentSky = currentForecastData["weather"][0]["main"];
          final currentPressure = currentForecastData["main"]["pressure"];
          final currentHumidity = currentForecastData["main"]["humidity"];
          final currentWindSpeed = currentForecastData["wind"]["speed"];

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
                      setState(() {
                        city = item!;
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
                                "${temp.toStringAsFixed(2)}` C",
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
                /*SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 1; i < 40; i++)
                        HourlyForecastItem(
                          icon: forecastData["list"][i]["weather"][0]["main"]
                                          .toString() ==
                                      "Clouds" ||
                                  forecastData["list"][i]["weather"][0]["main"]
                                          .toString() ==
                                      "Rain"
                              ? Icons.cloud
                              : Icons.sunny,
                          time: forecastData["list"][i]["dt"].toString(),
                          value: forecastData["list"][i]["main"]["temp"]
                              .toString(),
                        ),
                    ],
                  ),
                ),*/
                SizedBox(
                  height:
                      120, //SizeBox is needed otherwise the ListVie.builder will take up the entire screen
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final hourlyForecast = forecastData["list"][index + 1];
                      final hourlySky =
                          forecastData["list"][index + 1]["weather"][0]["main"]
                              .toString();
                      final dateTime = DateTime.parse(hourlyForecast["dt_txt"]);
                      final hourlyTemp = hourlyForecast["main"]["temp"]
                          .toString();
                      //print("$hourlySky, $dateTime, $hourlyTemp");
                      return HourlyForecastItem(
                        icon: hourlySky == "Clouds" || hourlySky == "Rain"
                            ? Icons.cloud
                            : Icons.sunny,
                        time: DateFormat.j().format(dateTime),
                        temp: hourlyTemp,
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
                      value: currentHumidity.toString(),
                    ),
                    AdditionalWeatherInfo(
                      icon: Icons.wind_power,
                      weatherType: "Wind Speed",
                      value: currentWindSpeed.toString(),
                    ),
                    AdditionalWeatherInfo(
                      icon: Icons.ac_unit,
                      weatherType: "Pressure",
                      value: currentPressure.toString(),
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

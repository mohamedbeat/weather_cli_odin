package odin

import "core:bufio"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor/odin-http/client"

Weather :: struct {
	description: string,
	icon:        string,
}

Main :: struct {
	temp:       f64,
	feels_like: f64,
	humidity:   u32,
}

Wind :: struct {
	speed: f64,
}

WeatherResp :: struct {
	name:    string,
	weather: []Weather,
	main:    Main,
	wind:    Wind,
}


main :: proc() {
	api_key, ok := os.lookup_env("OPENWEATHERMAP_APIKEY", context.allocator)

	if !ok {
		fmt.eprintf(
			"Error: OPENWEATHERMAP_APIKEY environment variable not set\nGet a free key at https://openweathermap.org/api\nThen run: export OWM_API_KEY=your_key_here",
		)
		return
	}

	city := "algeria"
	args := os.args[1:]

	if len(args) > 0 {
		city = args[0]
	}

	url := fmt.tprintf(
		"https://api.openweathermap.org/data/2.5/weather?q=%s&units=metric&appid=%s",
		city,
		api_key,
	)

	res, err := client.get(url)

	if err != nil {
		fmt.eprintln("Error fetching weather data: ", err)
		return
	}

	defer client.response_destroy(&res)


	body: strings.Builder
	strings.builder_init(&body)
	defer strings.builder_destroy(&body)

	for bufio.scanner_scan(&res._body) {
		strings.write_string(&body, bufio.scanner_text(&res._body))
		strings.write_byte(&body, '\n')
	}

	weather_res: WeatherResp
	jerr := json.unmarshal(transmute([]byte)strings.to_string(body), &weather_res)
	if jerr != nil {
		fmt.eprintln("Error decoding json: ", jerr)
		return
	}

	display_weather(weather_res)
}

display_weather :: proc(data: WeatherResp) {
	description: string
	if len(data.weather) > 0 {
		description = data.weather[0].description
	} else {
		description = "N/A"
	}

	icon: string
	if len(data.weather) > 0 {
		icon = data.weather[0].icon
	} else {
		icon = "01d"
	}

	fmt.printfln("------------------------------")
	fmt.printfln(" Weather in %s", data.name)
	fmt.printfln("------------------------------")
	fmt.printfln(" Condition  : %s %s", description, icon_to_emoji(icon))
	fmt.printfln(" Temp       : %f°C", data.main.temp)
	fmt.printfln(" Feels like : %f°C", data.main.feels_like)
	fmt.printfln(" Humidity   : %d%%", data.main.humidity)
	fmt.printfln(" Wind speed : %f m/s", data.wind.speed)
	fmt.printfln("------------------------------")
}

icon_to_emoji :: proc(icon: string) -> string {
	switch icon[:2] {
	case "01":
		return "☀️ " // clear sky
	case "02":
		return "⛅ " // few clouds
	case "03":
		return "🌥️ " // scattered clouds
	case "04":
		return "☁️ " // broken/overcast clouds
	case "09":
		return "🌧️ " // shower rain
	case "10":
		return "🌦️ " // rain
	case "11":
		return "⛈️ " // thunderstorm
	case "13":
		return "❄️ " // snow
	case "50":
		return "🌫️ " // mist/fog
	case:
		return "🌡️ " // fallback
	}
}

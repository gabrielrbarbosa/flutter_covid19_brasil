This repository is based on "flutter_google_maps_clusters" and its data is from https://github.com/wcota/covid19br.
This website also shows detailed info about covid-19 in Brazil - https://wcota.me/covid19br
Using flutter I think users can have a better usability in mobile.

![App COVID-19 Brasil](https://imgur.com/pknhu63.jpg)

HOW TO USE:
- Donwload app-release.apk and install it or

1. Clone or download this repository
2. Run flutter pub get / flutter create .
3. Change Google Maps API_KEY on AndroidManifest.xml or info.plist for iOS.
4. Run project and test it.

TODO:
- Show confirmed, active, recovered and deaths
- Group numbers by state (now it's showing by cities)
- External link to bing.com/covid for global map

* Requests using httpClient didn't get full csv file for some reason, so I'm using flutter_downloader to store the file locally and read it.


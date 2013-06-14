from models import *
import foursquareManager
import json


def getHumanDate(date):
    return date.strftime('%Y-%m-%d')


class SearchManager():

    def findNearVenues(self, latitude, longitude):
        response_data = []
        data = {}
        foursquare_result = foursquareManager.getVenusNearby(latitude, longitude)
        venues_results = foursquare_result['response']
        venues_results = venues_results['venues']

        for venues in venues_results:
            data['foursquare'] = venues
            data['has_wifi'] = 'True'
            data['wifi'] = self.getWifiByVenuId(venues['id'])
            if data['wifi'] is None:
                data['has_wifi'] = 'False'
            response_data.append(data)

        return response_data

    def findWifiByLocations(self, venues):
        ''' @TODO Ensure location data type '''

        query_result = models.Wifi.query(models.Wifi.venue_id.IN(venues)).fetch()
        return [wifi.to_dict() for wifi in query_result]

    @staticmethod
    def getLastestWifi(self, number=5):
        wifis = Wifi.query().fetch(number)
        result_query = []

        for wifi in wifis:
            wifi_fields = ['venue_id', 'venue_name', 'latitude', 'longitude', 'ssid', 'deprecate']
            data = {f: getattr(wifi, f) for f in wifi_fields}
            data['date_added'] = getHumanDate(wifi.date_added)

            for wifi_security in WifiSecurity.query(ancestor=wifi.key):
                data['password'] = wifi_security.password
                data['pass_date_added'] = getHumanDate(wifi_security.pass_date_added)
                data['date_last_update'] = getHumanDate(wifi_security.date_last_update)
                result_query.append(data)

        return result_query

    def getWifiByVenuId(self, venue_id):
        #wifi_result = Wifi.query(Wifi.venue_id == venue_id).fetch()
        wifi_result = Wifi.query(Wifi.venue_id == '23322').fetch()
        
        if len(wifi_result) == 0:
            return None

        wifi_fields = ['venue_id', 'venue_name', 'latitude', 'longitude', 'ssid', 'deprecate']
        data = {f: getattr(wifi_resul, f) for f in wifi_fields}
        data['date_added'] = getHumanDate(wifi_resul.date_added)

        for wifi_security in WifiSecurity.query(ancestor=wifi_resul.key):
            data['password'] = wifi_security.password
            data['pass_date_added'] = getHumanDate(wifi_security.pass_date_added)
            data['date_last_update'] = getHumanDate(wifi_security.date_last_update)
            result_query.append(data)

        return result_query

class WifiManager():

    def addWifi(self, venue_id, venue_name, latitude, longitude, ssid, has_password, password):
        wifi_security = models.WifiSecurity()
        return wifi_security.add(venue_id, venue_name, latitude, longitude, ssid, has_password, password)

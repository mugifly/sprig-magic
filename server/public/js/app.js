/**
	sprig::magic - AngularJS application script
**/
var app = angular.module('myApp', []);

// Config for POST request
// http://stackoverflow.com/questions/12190166/angularjs-any-way-for-http-post-to-send-request-parameters-instead-of-json
app.config(function ($httpProvider) {
	$httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
	$httpProvider.defaults.transformRequest = function(data){
		if (data === undefined) {
			return data;
		}
		return $.param(data);
	}
});

// Controller for the Aircon
app.controller('AirconCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.power = null;
	$scope.error_text = null;
	$scope.temperature_set = null;
	$scope.temperatures = [];
	for (var i = 18; i <= 30; i++) {
		$scope.temperatures.push({
			'label': i + '℃',
			'value': i
		});
	}

	// ----

	// Turn on/off the power of the aircon
	$scope.setPower = function (power) {
		if ($scope == null || power == $scope.power) {
			return;
		}

		$http.post('/aircon/status', { 'action' : 'set_power', 'power': power })
		.success( function(data){

		});
	};

	// Get the status of the aircon
	$scope.getStatus = function() {
		$http.get('/aircon/status')
		.success( function(data){
			if ($scope.power == null || $scope.power != data.aircon.power) {
				$scope.power = data.aircon.power;
				$('#switch_power').bootstrapSwitch('state', data.aircon.power);
			}
			$scope.power_brightness_sensor_value = data.aircon.power_brightness_sensor_value;
			$scope.temperature_real = data.aircon.temperature_real;
			$scope.temperature_set = data.aircon.temperature_set;
			// Clear the error text
			$scope.error_text = null;
		})
		.error(function(data, status, headers, config) {
			// Clear the error text
			$scope.error_text = data;
		});

		// Refresh interval
		$timeout( function(){
			$scope.getStatus();
		}, 4000);
	};

	$scope.setTemperature = function(temp) {
		if (temp == null) {
			return;
		}

		$http.post('/aircon/status', { 'action' : 'set_temperature', 'temperature': temp })
		.success( function(data){

		});
	};

	// ----
	
	$scope.getStatus();
}]);

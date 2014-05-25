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

// Controller for devices
app.controller('DevicesCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.error_text = null;
	$scope.devices = {};

	// ----

	// Get the devices
	$scope.getDevices = function() {
		$http.get(APP_BASEPATH + 'devices.json')
		.success( function(data){
			if (data.devices == null) {
				$scope.error_text = "デバイスのデータを取得できません";
				return;
			}

			$scope.devices = data.devices;

			// Clear the error text
			$scope.error_text = null;
		})
		.error(function(data, status, headers, config) {
			// Clear the error text
			$scope.error_text = data;
		});

		// Refresh interval
		$timeout( function(){
			$scope.getDevices();
		}, 4000);
	};

	// ----
	
	$scope.getDevices();
}]);

// Controller for Aircon
app.controller('AirconCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.temperature_set = $scope.device.operating_status.temperature_set; // This initial value is given from API
	$scope.temperatures = [];
	for (var i = 18; i <= 30; i++) {
		$scope.temperatures.push({
			'label': i + '℃',
			'value': i
		});
	}

	$timeout(function(){
		console.log($scope.device.operating_status.power);
		$('.switch_power_' + $scope.device.id).bootstrapSwitch('state', $scope.device.operating_status.power)
			.on('switchChange.bootstrapSwitch', function(event, state) {
				// Turn on/off
				angular.element(event.target).scope().setPower(state);
		});
	}, 100);

	// Watch for the power status
	$scope.before_status_power = $scope.device.operating_status.power;
	$scope.$watch(function(){
		return $scope.device.operating_status.power;
	}, function(current_power){
		if (current_power != $scope.before_status_power) {
			console.log("Change the status of power");
			$('.switch_power_' + $scope.device.id).bootstrapSwitch('state', $scope.device.operating_status.power);
			$scope.before_status_power = current_power;
		}
	});

	// ----

	// Turn on/off the power of the aircon
	$scope.setPower = function (power) {
		if ($scope == null || power == $scope.power) {
			return;
		}

		var device_id = $scope.device.id;
		$http.post(APP_BASEPATH + 'devices/' + device_id, {
			'command' : 'set_power=' + power
		})
		.success( function(data){
			console.log(data);
		});
	};

	$scope.setTemperature = function(temp) {
		if (temp == null) {
			return;
		}

		var device_id = $scope.device.id;
		$http.post(APP_BASEPATH + 'devices/' + device_id, {
			'command' : 'set_temperature=' + temp
		})
		.success( function(data){
			console.log(data);
		});
	};
}]);

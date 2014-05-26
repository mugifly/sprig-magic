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

// Directive to include the template for detail of the device
// e.g., Template for a device of the aircon category: <div include-device-detail-template="aircon"></div>
// Then, It will replaced to the template which detail of aircon devices (/partial_includes/template_device_detail/aircon.html)
app.directive('includeDeviceDetailTemplate', function($http, $compile) {
	return function(scope, element, attrs) {
		// Wait until the attribute is given
		attrs.$observe('includeDeviceDetailTemplate', function ( value ) { // Given value is the requested category name of a template
			var template_category = value;
			if (template_category == undefined || template_category == "") {
				return;
			}
			var template_url = APP_BASEPATH + '/partial_includes/template_device_detail/' + template_category + '.html';
			$http.get(template_url)
			.success(function(response) {
				element.html(response);
				$compile(element.contents())(scope);
			});
		});
	};
});

// Controller for devices
app.controller('DevicesCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.error_text = null;
	$scope.devices = {};

	// ----

	// Get devices
	$scope.getDevices = function() {
		$http.get(APP_BASEPATH + '/devices.json')
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


// Controller for device
app.controller('DeviceCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.error_text = null;
	if ($scope.parent == null || $scope.parent.devices == null) { //  If this scope isn't a partial of list of the devices, It must get a data myself.
		// Watch for when a value was specified on the DOM
		$scope.$watch(function(){
			return $scope.device_id;
		}, function(device_id){
			if (device_id != null) {
				$scope.getDevice(device_id);
				$scope.requestUpdateOperatingStatus(device_id);
			}
		});
	}

	// ----

	// Get the device
	$scope.getDevice = function(device_id) {
		$http.get(APP_BASEPATH + '/devices/' + device_id + '.json')
		.success( function(data){
			if (data.device == null) {
				$scope.error_text = "デバイスのデータを取得できません";
				return;
			}

			$scope.device = data.device;

			// Clear the error text
			$scope.error_text = null;
		})
		.error(function(data, status, headers, config) {
			// Clear the error text
			$scope.error_text = data;
		});

		// Refresh interval
		$timeout( function(){
			$scope.getDevice(device_id);
		}, 4000);
	};

	// Request updating of the operating status of the device
	$scope.requestUpdateOperatingStatus = function(device_id) {
		$http.post(APP_BASEPATH + '/devices/' + device_id + '.json', {
			'command' : 'update'
		})
		.success( function(data, status){
			// Refresh interval
			var interval = 5000;
			if (status == 208) { // If already requested with other clients
				interval = 15000;
			}
			$timeout( function(){
				$scope.requestUpdateOperatingStatus(device_id);
			}, interval);
		})
		.error( function(data, status){
			// Refresh interval
			$timeout( function(){
				$scope.requestUpdateOperatingStatus(device_id);
			}, 5000);
		});
	};
}]);

// Controller for Aircon
app.controller('AirconCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
	// Initialize 
	$scope.temperature_set = null;
	$scope.temperatures = [];
	for (var i = 18; i <= 30; i++) {
		$scope.temperatures.push({
			'label': i + '℃',
			'value': i
		});
	}

	$timeout(function(){
		$('.switch_power_' + $scope.device.id).bootstrapSwitch('state', $scope.device.operating_status.power)
			.on('switchChange.bootstrapSwitch', function(event, state) {
				// Turn on/off
				angular.element(event.target).scope().setPower(state);
		});
	}, 100);

	// Watch for the updating of the operating status
	$scope.before_operating_status = {};
	$scope.$watch(function(){
		return $scope.device.operating_status;
	}, function(operating_status){
		if ($scope.before_operating_status.power == null || operating_status.power != $scope.before_operating_status.power) {
			console.log("The status of power has been changed: " + operating_status.power);
			$('.switch_power_' + $scope.device.id).bootstrapSwitch('state', operating_status.power);
			$scope.before_operating_status.power = operating_status.power;
		}
		if ($scope.before_operating_status.temperature_set == null || operating_status.temperature_set != $scope.before_operating_status.temperature_set) {
			console.log("The set-temperature has been changed: " + operating_status.temperature_set);
			$scope.temperature_set =  operating_status.temperature_set;
			$scope.before_operating_status.temperature_set = operating_status.temperature_set;
		}
	});

	// ----

	// Turn on/off the power of the aircon
	$scope.setPower = function (power) {
		if ($scope == null || power == $scope.power) {
			return;
		}

		var device_id = $scope.device.id;
		$http.post(APP_BASEPATH + '/devices/' + device_id, {
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
		$http.post(APP_BASEPATH + '/devices/' + device_id, {
			'command' : 'set_temperature=' + temp
		})
		.success( function(data){
			console.log(data);
		});
	};
}]);

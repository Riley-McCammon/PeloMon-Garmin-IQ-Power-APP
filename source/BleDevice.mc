using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;

const DEVICE_NAME = "PeloMon";

const CPS = "00001818-0000-1000-8000-00805f9b34fb";
const CSCS = "00001816-0000-1000-8000-00805f9b34fb";
const UART = "6e40001-b5a3-f393-e0a9-e50e24dcca9e";

const CPS_SERVICE = Ble.stringToUuid(CPS);
const CPS_MEASUREMENT_CHAR = Ble.stringToUuid("00002A63-0000-1000-8000-00805f9b34fb");
const CPS_FEATURE_CHAR = Ble.stringToUuid("00002A65-0000-1000-8000-00805f9b34fb");
const CPS_SENSOR_LOC_CHAR = Ble.stringToUuid("00002A5D-0000-1000-8000-00805f9b34fb");
const CPS_MEASUREMENT_DESC = Ble.cccdUuid();


class BleDevice extends Ble.BleDelegate {
	var scanning = false;
	var device = null;
	var power = 0;

	hidden function debug(str) {
		System.println("[ble] " + str);
	}

	function initialize() {
		BleDelegate.initialize();
		debug("initialize");
	}

	function onCharacteristicChanged(ch, value) {
		debug("char read " + ch.getUuid() + " " + value);
		if (ch.getUuid().equals(CPS_MEASUREMENT_CHAR)) {
			power = value[0];
		}
	}

	function onProfileRegister(uuid, status) {
		debug("registered: " + uuid + " " + status);
	}

	function registerProfiles() {
		var profile = {
			:uuid => CPS_SERVICE,
			:characteristics => [{
				:uuid => CPS_SENSOR_LOC_CHAR,
			}, {
				:uuid => CPS_FEATURE_CHAR,
			}, {
				:uuid => CPS_MEASUREMENT_CHAR,
				:descriptors => [CPS_MEASUREMENT_DESC]
			}]
		};

		BluetoothLowEnergy.registerProfile(profile);
	}

	function onScanStateChange(scanState, status) {
		debug("scanstate: " + scanState + " " + status);
		if (scanState == Ble.SCAN_STATE_SCANNING) {
			scanning = true;
		} else {
			scanning = false;
		}
	}

	function onConnectedStateChanged(device, state) {
		debug("connected: " + device.getName() + " " + state);
		if (state == Ble.CONNECTION_STATE_CONNECTED) {
			self.device = device;
			var service;
			var ch;
			var desc;

			try{
				service = device.getService(CPS_SERVICE);
				if(service != null){
					ch = service.getCharacteristic(CPS_MEASUREMENT_CHAR);
					if(ch != null){
						desc = ch.getDescriptor(CPS_MEASUREMENT_DESC);
						if(desc != null){
							desc.requestWrite([0x01, 0x00]b);
						}
					}
				}
			} catch(e){
				debug("Error " + e.getErrorMessage());
				e.printStackTrace();
				throw e;
			}
		} else {
			self.device = null;
		}
	}

	private function connect(result) {
		debug("connect");
		var ret;
		Ble.setScanState(Ble.SCAN_STATE_OFF);
		Ble.pairDevice(result);
	}

	private function dumpUuids(iter) {
		for (var x = iter.next(); x != null; x = iter.next()) {
			debug("uuid: " + x);
		}
	}

	private function isPelomon(iter) {
		var uuids = [UART, CPS, CSCS];
		for (var x = iter.next(), i = 0; x != null; x = iter.next(), i++) {
			if(x != uuid[i]){
				debug("No match");
				return false;
			}
		}
		return true;
	}

	private function dumpMfg(iter) {
		for (var x = iter.next(); x != null; x = iter.next()) {
			debug("mfg: companyId: " + x.get(:companyId) + " data: " + x.get(:data));
		}
	}

	function onScanResults(scanResults) {
		debug("scan results");
		var appearance, name, rssi;
		var mfg, uuids, service;
		for (var result = scanResults.next(); result != null; result = scanResults.next()) {
			appearance = result.getAppearance();
			name = result.getDeviceName();
			rssi = result.getRssi();
			mfg = result.getManufacturerSpecificDataIterator();
			uuids = result.getServiceUuids();

			debug("device: appearance: " + appearance + " name: " + name + " rssi: " + rssi);
			dumpUuids(uuids);
			dumpMfg(mfg);

			if (isPelomon(result.getServiceUuids())) {
				connect(result);
				return;
			}
		}
	}

	function open() {
		registerProfiles();
		Ble.setScanState(Ble.SCAN_STATE_SCANNING);
	}

	function close() {
		debug("close");
		if (scanning) {
			Ble.setScanState(Ble.SCAN_STATE_OFF);
		}
		if (device) {
			Ble.unpairDevice(device);
		}
	}
}
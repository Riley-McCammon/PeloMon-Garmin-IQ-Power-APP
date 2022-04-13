import Toybox.WatchUi;
import Toybox.System;

class View extends WatchUi.SimpleDataField {
    hidden var bleDevice;

    // Set the label of the data field here.
    function initialize(device) {
        SimpleDataField.initialize();
        label = "Pelomon Power";
		    bleDevice = device;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // function compute(info as Activity.Info) as Numeric or Duration or String or Null {
    function compute(info) {

      if (bleDevice.scanning) {
        return "Scanning...";
      } else if (bleDevice.device == null) {
        return "Disconnected";
      }

      return bleDevice.power + "w";
    }

}
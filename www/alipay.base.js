/*global cordova, module*/

module.exports = {
	pay: function (order, successCallback, errorCallback) {
		cordova.exec(successCallback, errorCallback, "AliPayBase", "pay", [order]);
	}
};

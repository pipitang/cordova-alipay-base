/*global cordova, module*/

module.exports = {
	Base:{
		pay: function (order, successCallback, errorCallback) {
			cordova.exec(successCallback, errorCallback, "AlipayBase", "pay", [order]);
		}
	}
};

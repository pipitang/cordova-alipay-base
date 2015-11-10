/*global cordova, module*/

module.exports = {
	AliPay: {
		Base:{
	    	pay: function (order, successCallback, errorCallback) {
        		cordova.exec(successCallback, errorCallback, "AliPayBase", "pay", [order]);
    		}
		}
	}
};

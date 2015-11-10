package org.apache.cordova.alipay.base;

import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Log;

import com.alipay.sdk.app.PayTask;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Iterator;

public class AliPay extends CordovaPlugin {
    public static final String RESULT_STATUS = "resultStatus";
    public static final String RESULT = "result";
    public static final String MEMO = "memo";
    private static String TAG = "cordova-alipay-base";


    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "Execute:" + action + " with :" + args.toString());

        if (!action.equals("pay")) {
            callbackContext.error("无法识别服务");
            return true;
        }

        callPayService(args, callbackContext);
        return true;
    }

    private void callPayService(JSONArray args, final CallbackContext callbackContext) throws JSONException {
        final JSONObject arguments = args.getJSONObject(0);

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    String callString = buildCallString(arguments, callbackContext);
                    Log.d(TAG, "Calling Alipay with: ");
                    PayTask task = new PayTask(cordova.getActivity());
                    // 调用支付接口，获取支付结果
                    final String rawResult = task.pay(callString);
                    Log.d(TAG, "Alipay returns:" + rawResult);
                    final JSONObject result = buildPaymentResult(rawResult);
                    cordova.getActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            callbackContext.success(result);
                        }
                    });
                }
                catch (JSONException e){
                    Log.e(TAG, "Manipulating json", e);
                    callbackContext.error("Manipulating json");
                }
            }

        });
    }

    private String buildCallString(JSONObject args, CallbackContext context) throws JSONException {
        StringBuffer buf = new StringBuffer();

        Iterator<String> itr = args.keys();
        while (itr.hasNext()) {
            String key = itr.next();
            String value = args.getString(key);
            if (!TextUtils.isEmpty(value)) {
                buf.append(key).append('=');
                buf.append('"').append(value).append('"');
                buf.append('&');
            }
        }
        if (buf.length() > 0) buf.deleteCharAt(buf.length() - 1);
        return buf.toString();
    }


    private JSONObject buildPaymentResult(String rawResult) throws JSONException {
        JSONObject result = new JSONObject();
        String[] resultParams = rawResult.split(";");
        for (String resultParam : resultParams) {
            if (resultParam.startsWith(RESULT_STATUS))
                result.put(RESULT_STATUS, gatValue(resultParam, RESULT_STATUS));
            if (resultParam.startsWith(RESULT))
                result.put(RESULT, gatValue(resultParam, RESULT));
            if (resultParam.startsWith(MEMO)) result.put(MEMO, gatValue(resultParam, MEMO));
        }
        return result;
    }


    private String gatValue(String content, String key) {
        String prefix = key + "={";
        return content.substring(content.indexOf(prefix) + prefix.length(), content.lastIndexOf("}"));
    }

}

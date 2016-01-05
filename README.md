# cordova-alipay-base 

Cordova 支付宝基础功能插件

# 功能

目前只有支付功能

# 安装

1. 运行

```
cordova plugin add https://github.com/pipitang/cordova-alipay-base --variable ALI_PID=yourpid

```

2. cordova各种衍生命令行都应该支持，例如phonegap或者ionic。

# 使用方法

## 注意

阿里官方的例子只是演示了支付参数的调用，在实际项目中决不可使用。在客户端使用appkey，更别提private_key了，危险隐患重重。

安全的使用方式应该是由服务端保存key，然后根据客户端传来的订单id，装载订单内容，生成支付字符串，最后由客户端提交给支付网关。另外，服务端返回支付字符串时，除了签名顺序一致以外，合成的key=value是要带双引号的，这点比较坑爹，害了我调试半天, 想见后面Java代码:

```
public static String createLinkString(Map<String, String> params, boolean client) {
	List<String> keys = new ArrayList<String>(params.keySet());
	Collections.sort(keys);

	StringBuffer buf = new StringBuffer();

	for (int i = 0; i < keys.size(); i++) {
		String key = keys.get(i);
		String value = params.get(key);
		buf.append(key).append('=');
		if (client) buf.append('"');
		buf.append(value); 
		if (client) buf.append('"');
		buf.append('&');
	}

	buf.deleteCharAt(buf.length()-1);
	return buf.toString();
}

```

我们的项目中为了兼容微信支付，生成checkout返回的信息为json对象，其实本质上字符串即可。。


## API

### 支付API


```
    Alipay.Base.pay(parameters, success, failure); 

```

此处第一个参数为json对象，请从服务端获取，直接传给改方法。客户端会对服务端返回的JSON对象属性进行排序，js层不需要关心。具体服务端参数合成，java代码请参照一下内容及阿里官方文档，注意createLinkString上得注释：

在项目中客户端使用如下：
```
orderService.checkout(orderId, $scope.selectPay).then(function (parameters) {
    if ('Wechat' === $scope.selectPay) callNativeWexinPayment(parameters); {
    else Alipay.Base.pay(parameters, function(result){
        if(result.resultStatus==='9000'||result.resultStatus==='8000') finishPayment();
        else showPaymentError(null);
    }, showPaymentError);
}

```

服务端如下，可以把Map直接作为JSON返回：

```
private static Map<String, String> checkoutAlipay(AlipayConfig config, String orderNumber, BigDecimal amount) throws Exception{
    Map<String, String> orderInfo=new HashMap<String,String>();
    orderInfo.put("service", "mobile.securitypay.pay");
    orderInfo.put("partner", aliConfig.getPartnerId());
    orderInfo.put("_input_charset", "utf-8");
    orderInfo.put("notify_url", aliConfig.getPaymentConfirm());
    orderInfo.put("out_trade_no", orderNumber);

    orderInfo.put("total_fee", amount + "");
    orderInfo.put("subject", "XXXXXX收费");

    orderInfo.put("payment_type", "1");
    orderInfo.put("seller_id", aliConfig.getSellerId());
    orderInfo.put("body", "xxxx yykskdfksdf 服务费");

    // 设置未付款交易的超时时间
    // 默认30分钟，一旦超时，该笔交易就会自动被关闭。
    // 取值范围：1m～15d。
    // m-分钟，h-小时，d-天，1c-当天（无论交易何时创建，都在0点关闭）。
    // 该参数数值不接受小数点，如1.5h，可转换为90m。
    orderInfo.put("it_b_pay", "7d");
    // extern_token为经过快登授权获取到的alipay_open_id,带上此参数用户将使用授权的账户进行支付
    // orderInfo += "&extern_token=" + "\"" + extern_token + "\"";
    // We have to tell the client
    orderInfo.put("sign", URLEncoder.encode(AlipayUtil.sign(orderInfo, aliConfig.getPrivateKey()), "utf-8"));
    orderInfo.put("sign_type", "RSA");
    return orderInfo;
}

```

```
public class AlipayConfig {

    private String partnerId;
    private String paymentConfirm;
    private String sellerId;
    private String privateKey;
    private String publicKey;

    public String getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(String partnerId) {
        this.partnerId = partnerId;
    }

    public String getPaymentConfirm() {
        return paymentConfirm;
    }

    public void setPaymentConfirm(String paymentConfirm) {
        this.paymentConfirm = paymentConfirm;
    }

    public String getSellerId() {
        return sellerId;
    }

    public void setSellerId(String sellerId) {
        this.sellerId = sellerId;
    }

    public String getPrivateKey() {
        return privateKey;
    }

    public void setPrivateKey(String privateKey) {
        this.privateKey = privateKey;
    }

    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }
}

```

```

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.crypto.Cipher;

import org.springframework.util.Base64Utils;

public abstract class AlipayUtil {
    public static final String SIGN_ALGORITHMS = "SHA1WithRSA";
    /** 支付宝消息验证地址 */
    private static final String HTTPS_VERIFY_URL = "https://mapi.alipay.com/gateway.do?service=notify_verify&";

    public static String sign(Map<String, String> content, String privateKey) throws Exception {
        return sign(createLinkString(content, true), privateKey, "utf-8");
    }

    /** RSA签名
    * @param content 待签名数据
    * @param privateKey 商户私钥
    * @param input_charset 编码格式
    * @return 签名值
    * @throws Exception */
    private static String sign(String content, String privateKey, String input_charset) throws Exception {
        PKCS8EncodedKeySpec priPKCS8 = new PKCS8EncodedKeySpec(Base64Utils.decodeFromString(privateKey));
        KeyFactory keyf = KeyFactory.getInstance("RSA");
        PrivateKey priKey = keyf.generatePrivate(priPKCS8);
        java.security.Signature signature = java.security.Signature.getInstance(SIGN_ALGORITHMS);
        signature.initSign(priKey);
        signature.update(content.getBytes(input_charset));
        byte[] signed = signature.sign();
        return Base64Utils.encodeToString(signed);
    }

    /** RSA验签名检查
    * @param content 待签名数据
    * @param sign 签名值
    * @param ali_public_key 支付宝公钥
    * @param input_charset 编码格式
    * @return 布尔值 */
    private static boolean verify(String content, String sign, String ali_public_key, String input_charset) {
        try {
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            byte[] encodedKey = Base64Utils.decodeFromString(ali_public_key);
            PublicKey pubKey = keyFactory.generatePublic(new X509EncodedKeySpec(encodedKey));
            java.security.Signature signature = java.security.Signature.getInstance(SIGN_ALGORITHMS);
            signature.initVerify(pubKey);
            signature.update(content.getBytes(input_charset));
            return signature.verify(Base64Utils.decodeFromString(sign));
        } catch (Exception e) { e.printStackTrace();}

        return false;
    }

    /** 解密
    * @param content 密文
    * @param private_key 商户私钥
    * @param input_charset 编码格式
    * @return 解密后的字符串 */
    public static String decrypt(String content, String private_key, String input_charset) throws Exception {
        PrivateKey prikey = getPrivateKey(private_key);
        Cipher cipher = Cipher.getInstance("RSA");
        cipher.init(Cipher.DECRYPT_MODE, prikey);
        InputStream ins = new ByteArrayInputStream(Base64Utils.decodeFromString(content));
        ByteArrayOutputStream writer = new ByteArrayOutputStream();
        // rsa解密的字节大小最多是128，将需要解密的内容，按128位拆开解密
        byte[] buf = new byte[128];
        int bufl;

        while ((bufl = ins.read(buf)) != -1) {
            byte[] block = null;

            if (buf.length == bufl) {
                block = buf;
            } else {
                block = new byte[bufl];
                for (int i = 0; i < bufl; i++) {
                    block[i] = buf[i];
                }
            }
            writer.write(cipher.doFinal(block));
        }

        return new String(writer.toByteArray(), input_charset);
    }

    /** 得到私钥
    * @param key 密钥字符串（经过base64编码）
    * @throws Exception */
    public static PrivateKey getPrivateKey(String key) throws Exception {
        byte[] keyBytes = Base64Utils.decodeFromString(key);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
        return privateKey;
    }

    /** 除去数组中的空值和签名参数
    * @param sArray 签名参数组
    * @return 去掉空值与签名参数后的新签名参数组 */
    public static Map<String, String> paraFilter(Map<String, String> sArray) {

        Map<String, String> result = new HashMap<String, String>();

        if (sArray == null || sArray.size() <= 0) { return result; }

        for (String key : sArray.keySet()) {
        String value = sArray.get(key);
        if (value == null || value.equals("") || key.equalsIgnoreCase("sign") || key.equalsIgnoreCase("sign_type")){
            continue;
            }
            result.put(key, value);
        }

        return result;
    }

    /** 把数组所有元素排序，并按照“参数=参数值”的模式用“&”字符拼接成字符串
    * @param params 需要排序并参与字符拼接的参数组
    * @param client 是否用于给客户端合成签名使用，AliPay的设计实在让人郁闷，提交的数据需要双引号把内容括起来，但是向我们服务器通知的数据居然没有引号。
    * @return 拼接后字符串 */
    public static String createLinkString(Map<String, String> params, boolean client) {
        List<String> keys = new ArrayList<String>(params.keySet());
        Collections.sort(keys);

        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < keys.size(); i++) {
            String key = keys.get(i);
            String value = params.get(key);
            buf.append(key).append('=');
            if (client) buf.append('"');
            buf.append(value); 
            if (client) buf.append('"');
            buf.append('&');
        }

        buf.deleteCharAt(buf.length()-1);
        return buf.toString();
    }


    /** 验证消息是否是支付宝发出的合法消息
    * @param params 通知返回来的参数数组
    * @return 验证结果 */
    public static boolean verify(Map<String, String> params, String partner, String publicKey) {

        // 判断responsetTxt是否为true，isSign是否为true
        // responsetTxt的结果不是true，与服务器设置问题、合作身份者ID、notify_id一分钟失效有关
        // isSign不是true，与安全校验码、请求时的参数格式（如：带自定义参数等）、编码格式有关
        String responseTxt = "false";
        if (params.get("notify_id") != null) {
            String notify_id = params.get("notify_id");
            responseTxt = verifyResponse(notify_id, partner);
        }
        String sign = "";
        if (params.get("sign") != null) {
            sign = params.get("sign");
        }
        boolean isSign = getSignVeryfy(params, sign, publicKey);
        return isSign && responseTxt.equals("true");
    }

    /** 根据反馈回来的信息，生成签名结果
    * @param Params 通知返回来的参数数组
    * @param sign 比对的签名结果
    * @return 生成的签名结果 */
    private static boolean getSignVeryfy(Map<String, String> Params, String sign, String publicKey) {
        // 过滤空值、sign与sign_type参数, 获取待签名字符串
        String preSignStr = createLinkString(paraFilter(Params), false);
        // 获得签名验证结果
        return verify(preSignStr, sign, publicKey, "utf-8");
    }

    /** 获取远程服务器ATN结果,验证返回URL
    * @param notify_id 通知校验ID
    * @return 服务器ATN结果 验证结果集： invalid命令参数不对 出现这个错误，请检测返回处理中partner和key是否为空 true 返回正确信息 false 请检查防火墙或者是服务器阻止端口问题以及验证时间是否超过一分钟 */
    private static String verifyResponse(String notify_id, String partner) {
        // 获取远程服务器ATN结果，验证是否是支付宝服务器发来的请求
        String veryfy_url = HTTPS_VERIFY_URL + "partner=" + partner + "&notify_id=" + notify_id;
        return checkUrl(veryfy_url);
    }

    /** 获取远程服务器ATN结果
    * @param urlvalue 指定URL路径地址
    * @return 服务器ATN结果 验证结果集： invalid命令参数不对 出现这个错误，请检测返回处理中partner和key是否为空 true 返回正确信息 false 请检查防火墙或者是服务器阻止端口问题以及验证时间是否超过一分钟 */
    private static String checkUrl(String urlvalue) {
        String inputLine = "";

        try {
            URL url = new URL(urlvalue);
            HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
            BufferedReader in = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
            inputLine = in.readLine().toString();
        } catch (Exception e) {
            e.printStackTrace();
            inputLine = "";
        }

        return inputLine;
    }
}

```

# FAQ

Q: Android如何调试？

A: 如果怀疑插件有BUG，请使用tag名称为cordova-alipay-base查看日志。

Q: Windows 版本？

A: 这个很抱歉，有个哥们买了Lumia之后一直在抱怨应用太少，你也很不幸，有这个需求：） 欢迎 pull request.


# TODO

# 许可证

[MIT LICENSE](http://opensource.org/licenses/MIT)

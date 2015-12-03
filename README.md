# cordova-alipay-base 

Cordova 支付宝基础功能插件

# 功能

目前只有支付功能

# 安装

1. 运行

```
cordova plugin add https://github.com/pipitang/cordova-alipay-base --variables ALI_PID=yourpid

```

2. cordova各种衍生命令行都应该支持，例如phonegap或者ionic。

# 使用方法

## 注意

阿里官方的例子只是演示了支付参数的调用，在实际项目中决不可使用。在客户端使用appkey，更别提private_key了，危险隐患重重。

安全的使用方式应该是由服务端保存key，然后根据客户端传来的订单id，装载订单内容，生成支付字符串，最后由客户端提交给支付网关。另外，服务端返回支付字符串时，除了签名顺序一致以外，合成的key=value是要带双引号的，这点比较坑爹，害了我调试半天。可参照一下代码，有时间会把服务端代码抽取出来供大家使用:

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


```Javascript
Alipay.Base.pay({
    xxxx: 'value', 
    signType: 'RSA'
}, function () {
    alert("支付成功");
}, function (reason) {
    alert("支付失败");
});
```

此处第一个参数为json对象，请从服务端获取，直接传给改方法。具体服务端参数合成，请参照阿里相关文档。客户端会对服务端返回的JSON对象属性进行排序，js层不需要关心。

# FAQ

Q: Android如何调试？

A: 如果怀疑插件有BUG，请使用tag名称为cordova-alipay-base查看日志。

Q: Windows 版本？

A: 这个很抱歉，有个哥们买了Lumia之后一直在抱怨应用太少，你也很不幸，有这个需求：） 欢迎 pull request.


# TODO

# 许可证

[MIT LICENSE](http://opensource.org/licenses/MIT)

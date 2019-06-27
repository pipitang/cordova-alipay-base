# WARN
***本项目已经于2016年停止更新，请查看他人分支或寻求阿里官方支持***

# cordova-alipay-base 

Cordova 支付宝基础功能插件

# 功能

仅实现APP的支付宝支付功能

# 安装

0. 背景

本插件来源于 https://github.com/pipitang/cordova-alipay-base ，根据最新的SDK做了修正。

配套提交了ionic-native插件。

1. 运行

```
cordova plugin add https://github.com/xueron/cordova-alipay-base --variable APP_ID=your_app_id

```

2. cordova各种衍生命令行都应该支持，例如phonegap或者ionic。

# 使用方法

## 注意

阿里官方的例子只是演示了支付参数的调用，在实际项目中决不可使用。在客户端使用appkey，更别提private_key了，危险隐患重重。

安全的使用方式应该是由服务端保存key，然后根据客户端传来的订单id，装载订单内容，生成支付字符串，最后由客户端提交给支付网关。

## API

### 支付API


```
    Alipay.Base.pay(parameters, success, failure); 

```

此处第一个参数为json对象，请从服务端获取，直接传给改方法。
客户端会对服务端返回的JSON对象属性进行排序，js层不需要关心。具体服务端参数合成，java代码请参照一下内容及阿里官方文档，注意createLinkString上得注释：

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

ionic 2使用方法如下：
```
import { Alipay, AlipayOrder } from 'ionic-native';

......
  payInfo: AlipayOrder; // 从服务器端返回。

......
    Alipay.pay(this.payInfo)
      .then(res => {
        console.log(res);
        this.payResult = res;
      }, err => {
        console.log(err);
        this.payResult = err;
      })
      .catch(e => {
        console.log(e);
        this.payResult = e;
      });
......

```

服务端如下，(PHP)JSON返回：

```
                //组装系统参数
                $params["app_id"] = $alipayOrder->app_id;
                $params["method"] = 'alipay.trade.app.pay';
                $params["format"] = 'json';
                $params["charset"] = 'UTF-8';
                $params["sign_type"] = 'RSA';
                $params["timestamp"] = date("Y-m-d H:i:s");
                $params["version"] = '1.0';
                $params["notify_url"] = $alipayOrder->notify_url;
                $params["biz_content"] = $alipayOrder->biz_content;
                $sign = $this->getDI()->get(AlipayService::class)->sign($params);
                $this->logger->debug("支付签名=$sign");
                $params['sign'] = $sign;

                //
                array_walk($params, function (&$v, $k) {
                    $v = urlencode($v);
                });

                return json_encode($params);

```

# FAQ

Q: Android如何调试？

A: 如果怀疑插件有BUG，请使用tag名称为cordova-alipay-base查看日志。

Q: Windows 版本？

A: 这个很抱歉，有个哥们买了Lumia之后一直在抱怨应用太少，你也很不幸，有这个需求：） 欢迎 pull request.


# TODO

# 许可证

[MIT LICENSE](http://opensource.org/licenses/MIT)

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

此处第一个参数为json对象，请从服务端获取，直接传给改方法。具体服务端参数合成，请参照阿里相关文档。

# FAQ

Q: Android如何调试？

A: 如果怀疑插件有BUG，请使用tag名称为cordova-alipay-base查看日志。

Q: Windows 版本？

A: 这个很抱歉，有个哥们买了Lumia之后一直在抱怨应用太少，你也很不幸，有这个需求：） 欢迎 pull request.


# TODO

# 许可证

[MIT LICENSE](http://opensource.org/licenses/MIT)

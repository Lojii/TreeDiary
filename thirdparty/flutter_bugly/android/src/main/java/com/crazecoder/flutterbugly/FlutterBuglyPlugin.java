package com.crazecoder.flutterbugly;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.crazecoder.flutterbugly.bean.BuglyInitResultInfo;
import com.crazecoder.flutterbugly.utils.JsonUtil;
import com.crazecoder.flutterbugly.utils.MapUtil;
import com.tencent.bugly.Bugly;
import com.tencent.bugly.BuglyStrategy;
import com.tencent.bugly.crashreport.CrashReport;

import java.util.HashMap;
import java.util.Map;

import io.flutter.BuildConfig;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterBuglyPlugin
 */
public class FlutterBuglyPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private Result result;
    private boolean isResultSubmitted = false;
    private static MethodChannel channel;
    @SuppressLint("StaticFieldLeak")
    private static Activity activity;
    private FlutterPluginBinding flutterPluginBinding;


    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), "crazecoder/flutter_bugly");
        FlutterBuglyPlugin plugin = new FlutterBuglyPlugin();
        channel.setMethodCallHandler(plugin);
        activity = registrar.activity();
    }

    @Override
    public void onMethodCall(final MethodCall call, @NonNull final Result result) {
        isResultSubmitted = false;
        this.result = result;
        if (call.method.equals("initBugly")) {
            if (call.hasArgument("appId")) {
                String appId = call.argument("appId").toString();
                // 设置device_id, sdk默认读取android_id, 有可能导致应用上线审核不通过: https://bugly.qq.com/docs/user-guide/advance-features-android/?v=20200622202242#userstrategy
                String deviceId = "android";
                if (call.hasArgument("channel")) {
                    deviceId = call.argument("channel");
                }
                if (TextUtils.isEmpty(deviceId)) {
                    deviceId = "android";
                }
                BuglyStrategy strategy = new BuglyStrategy();
                strategy.setDeviceID(deviceId);
                Bugly.init(activity.getApplicationContext(), appId, BuildConfig.DEBUG, strategy);

                if (call.hasArgument("channel")) {
                    String channel = call.argument("channel");
                    if (!TextUtils.isEmpty(channel))
                        CrashReport.setAppChannel(activity.getApplicationContext(), channel);
                }
                result(getResultBean(true, appId, "Bugly 初始化成功"));
            } else {
                result(getResultBean(false, null, "Bugly appId不能为空"));
            }
        } else if (call.method.equals("setUserId")) {
            if (call.hasArgument("userId")) {
                String userId = call.argument("userId");
                CrashReport.setUserId(activity.getApplicationContext(), userId);
            }
            result(null);
        } else if (call.method.equals("setUserTag")) {
            if (call.hasArgument("userTag")) {
                Integer userTag = call.argument("userTag");
                if (userTag != null)
                    CrashReport.setUserSceneTag(activity.getApplicationContext(), userTag);
            }
            result(null);
        } else if (call.method.equals("putUserData")) {
            if (call.hasArgument("key") && call.hasArgument("value")) {
                String userDataKey = call.argument("key");
                String userDataValue = call.argument("value");
                CrashReport.putUserData(activity.getApplicationContext(), userDataKey, userDataValue);
            }
            result(null);
        } else if (call.method.equals("setAppChannel")) {
            String channel = call.argument("channel");
            if (!TextUtils.isEmpty(channel)) {
                CrashReport.setAppChannel(activity.getApplicationContext(), channel);
            }
            result(null);
        } else if (call.method.equals("postCatchedException")) {
            postException(call);
            result(null);
        } else {
            result.notImplemented();
            isResultSubmitted = true;
        }

    }

    private void postException(MethodCall call) {
        String message = "";
        String detail = null;
        if (call.hasArgument("crash_message")) {
            message = call.argument("crash_message");
        }
        if (call.hasArgument("crash_detail")) {
            detail = call.argument("crash_detail");
        }
        if (TextUtils.isEmpty(detail)) return;
        CrashReport.postException(8, "Flutter Exception", message, detail, null);

    }

    private void result(Object object) {
        if (result != null && !isResultSubmitted) {
            if (object == null) {
                result.success(null);
            } else {
                result.success(JsonUtil.toJson(MapUtil.deepToMap(object)));
            }
            isResultSubmitted = true;
        }
    }

    private BuglyInitResultInfo getResultBean(boolean isSuccess, String appId, String msg) {
        BuglyInitResultInfo bean = new BuglyInitResultInfo();
        bean.setSuccess(isSuccess);
        bean.setAppId(appId);
        bean.setMessage(msg);
        return bean;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = binding;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        flutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "crazecoder/flutter_bugly");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
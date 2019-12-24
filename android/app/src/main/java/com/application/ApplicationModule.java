package com.application;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Map;

public class ApplicationModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

    private ReactContext mReactContext;
    private Boolean mBackGestureEnabled;

    public ApplicationModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.mReactContext = reactContext;
        this.mBackGestureEnabled = true;
        ApplicationBroadcastManager.addModule(this);
        Log.d("@@init", "ApplicationModule init");
        reactContext.addLifecycleEventListener(this);
    }

    @Override
    public String getName() {
        return "Application";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        // 当前模块版本号 {String}
        constants.put("application_module_version", "1.0.0");

        // 当前应用配置信息 {Object}
        ApplicationConfigManager.getInstance().setupContext(mReactContext);
        constants.put("config", ApplicationConfigManager.getInstance().getConfigObject());

        // 当前应用环境 key {String}
        constants.put("environmentKey", ApplicationConfigManager.getInstance().getCurrentEnvironemntKey());

        // 当前应用环境对应的飞燕 AppId {String}
        // final String appKey = APIGatewayHttpAdapterImpl.getAppKey(mReactContext, BaseConstant.DEFAULT_SECURITY_IMAGE_POSTFIX);
        // constants.put("appId", appKey);

        return constants;
    }

    @ReactMethod
    public void loadPageWithOptions(ReadableMap options) {
        Log.d("options", options.toString());
        Intent intent = new Intent(mReactContext, RCTActivity.class);
        // send data to next activity
        intent.putExtra("options", options.toHashMap());
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mReactContext.startActivity(intent);
    }

    @ReactMethod
    public void back() {
        // mReactContext.getCurrentActivity().finish();
        ActivityCache.back();
    }

    @ReactMethod
    public void backHome() {
//        Intent intent = new Intent(mReactContext, RCTActivity.class);
//        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
//        mReactContext.startActivity(intent);
        ActivityCache.backHome();
    }

    // test reload activity
    @ReactMethod
    public void reload() {
        ActivityCache.reloadTopActivity();
    }

    @ReactMethod
    public void exit() {
        ActivityCache.exit();
        System.exit(0);
    }


    /**
     * 给RN发送通知
     *
     * @param eventName
     * @param params
     */
    private void sendEvent(String eventName, ReadableMap params) {
        mReactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(
                        eventName,
                        Arguments.makeNativeMap(params.toHashMap())
                );
    }

    /**
     * 跨 React Native 广播方法
     */
    @ReactMethod
    public void broadcast(ReadableMap payload) {
        ApplicationBroadcastManager.boardcast(payload);
    }

    public void sendBroadcastContentToReactNative(ReadableMap payload) {
        sendEvent("application_broadcast", payload);
    }


    /**
     * 获取应用开发者模式
     */
    @ReactMethod
    public void getDeveloperMode(final Callback reactNativeCallBack) {
        reactNativeCallBack.invoke(ApplicationPreferencesManager.getDeveloperMode());
    }

    /**
     * 设定应用开发者模式
     */
    @ReactMethod
    public void setDeveloperMode(Boolean targetMode, final Callback reactNativeCallback) {
        ApplicationPreferencesManager.setDeveloperMode(targetMode);
        reactNativeCallback.invoke(true);
    }

    /**
     * 移除当前页面
     */
    @ReactMethod
    public void removePage() {
        Activity activity = getCurrentActivity();
        if (activity != null) {
            activity.finish();
        }
    }

    public Activity currentActivity() {
        return getCurrentActivity();
    }

    public void sendPageLifeCycleEvent(ReadableMap payload) {
        sendEvent("application_page_status", payload);
    }

    public void finishCurrentActivity() {
        if (this.mBackGestureEnabled) {
            currentActivity().finish();
        }
    }

    /**
     * 启用返回手势操作
     * 仅支持 iOS
     */
    @ReactMethod
    public void enableBackGesture() {
        this.mBackGestureEnabled = true;
    }

    /**
     * 启用返回手势操作
     * 仅支持 iOS
     */
    @ReactMethod
    public void disableBackGesture() {
        this.mBackGestureEnabled = false;
    }

    /**
     * React Native 业务层逻辑已准备完毕
     */
    @ReactMethod
    public void ready() {
        ActivityCache.ready();
    }


    /**
     * 监听 Activity 状态变化
     */

    @Override
    public void onHostResume() {
        // Activity `onResume`
    }

    @Override
    public void onHostPause() {
        // Activity `onPause`
    }

    @Override
    public void onHostDestroy() {
        // Activity `onDestroy`
        ApplicationBroadcastManager.removeModule(this);
    }


    /**
     * 连接到指定 SSID Wi-Fi
     * @param data {ssid: string, password: string}
     * @param reactNativeCallBack
     */
    @ReactMethod
    public void connectSSID(ReadableMap data, final Callback reactNativeCallBack) {
        // Android 无需实现此方法
    }

    private void printSecurityImageInformation() {
        /*
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Bitmap bitmap = BitmapFactory.decodeResource(this.mReactContext.getResources(), R.drawable.yw_1222_114d);
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, baos);
        byte[] imageBytes = baos.toByteArray();
        String imageString = Base64.encodeToString(imageBytes, Base64.DEFAULT);
        Log.d("@checkImage", imageString);
        //*/
    }

    @ReactMethod
    public void switchEnvironment(String targetEnvironemnt, final Callback reactNativeCallback) {
        ApplicationConfigManager.getInstance().setupContext(mReactContext);
        Log.d("@targetEnvironemnt", targetEnvironemnt);
        Boolean switchEnvironmentSuccess = ApplicationConfigManager.getInstance().setCurrentEnvironmentKey(targetEnvironemnt);
        HashMap<String, Object> error;
        if (!switchEnvironmentSuccess) {
            error = new HashMap<String, Object>();
            error.put("code", "1");
            reactNativeCallback.invoke(error); //TODO: 修改格式为包含错误代码格式
        }
        reactNativeCallback.invoke();
    }

}
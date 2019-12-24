package com.application;

import android.os.Handler;
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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import qk.sdk.mesh.meshsdk.MeshHelper;
import qk.sdk.mesh.meshsdk.MeshSDK;
import qk.sdk.mesh.meshsdk.callbak.ArrayMapCallback;
import qk.sdk.mesh.meshsdk.callbak.IntCallback;

public class BLEMeshModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

    int count = 0;

    private ReactContext mReactContext;

    public BLEMeshModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.mReactContext = reactContext;
        Log.d("@init", "BLEMeshModule init");


        MeshSDK.INSTANCE.init(reactContext);
    }

    @Override
    public String getName() {
        return "BLEMeshModule";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        // 当前模块版本号 {String}
        constants.put("version", "1.0.0");

        return constants;
    }

    @ReactMethod
    public void test(ReadableMap options, final Callback callback) {
        Log.d("@BLEMeshModule", "options: " + options.toString());

        Handler handler = new Handler(mReactContext.getMainLooper());
        handler.post(new Runnable(){

            @Override
            public void run() {
                MeshSDK.INSTANCE.startScan("unProvisioned", new ArrayMapCallback() {
                    @Override
                    public void onResult(ArrayList<HashMap<String, Object>> arrayList) {
                        Log.d("@BLEMeshModule", "onResult");
                        if (count == 0) {
                            callback.invoke(null, Arguments.makeNativeArray(arrayList));
                            count += 1;
                        }
                    }
                }, new IntCallback() {
                    @Override
                    public void onResultMsg(int i) {
                        Log.d("@BLEMeshModule", "onResultMsg");
                        callback.invoke(i);
                    }
                });
            }
        });
        /*
        MeshSDK.INSTANCE.startScan("unProvisioned", new ArrayMapCallback() {
            @Override
            public void onResult(ArrayList<HashMap<String, Object>> arrayList) {
                callback.invoke(null, Arguments.makeNativeArray(arrayList));
            }
        }, new IntCallback() {
            @Override
            public void onResultMsg(int i) {
                callback.invoke(i);
            }
        });
        //*/
    }

    @ReactMethod
    public void a() {
        Log.d("@BLEMeshModule", "a()");
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
    }

}
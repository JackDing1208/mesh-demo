package com.application;

import android.app.Activity;

import com.facebook.react.bridge.ReadableMap;

import java.util.LinkedList;
import java.util.List;

public class ApplicationBroadcastManager {
    public static List<ApplicationModule> moduleList = new LinkedList<ApplicationModule>();

    public ApplicationBroadcastManager() {

    }

    static public void addModule(ApplicationModule module) {
        if (!moduleList.contains(module)) {
            moduleList.add(module);
        }
    }

    static public void removeModule(ApplicationModule module) {
        for(int i=moduleList.size()-1; i>=0; i--) {
            ApplicationModule moduleItem = moduleList.get(i);
            if (moduleItem == module) {
                moduleList.remove(module);
            }
        }
    }

    /**
     * 广播消息给所有 ApplicationModule
     * @param payload
     */
    static public void boardcast(ReadableMap payload) {
        for(int i=0; i<moduleList.size(); i++) {
            ApplicationModule moduleItem = moduleList.get(i);
            moduleItem.sendBroadcastContentToReactNative(payload);
        }
    }

    static public void sendPageLifeCycleEvent(ReadableMap payload, Activity sourceActivity) {
        List<ApplicationModule> needSendEventModuleList = new LinkedList<ApplicationModule>();
        for(int i=0; i<moduleList.size(); i++) {
            ApplicationModule moduleItem = moduleList.get(i);
            Activity currentActivity = moduleItem.currentActivity();
            if (currentActivity == null) {
                continue;
            }
            if (currentActivity.equals(sourceActivity)) {
                 moduleItem.sendPageLifeCycleEvent(payload);
            }
        }
    }

    static public ApplicationModule topApplicationModule() {
        return moduleList.get(moduleList.size() - 1);
    }


}

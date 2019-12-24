package com.application;

import android.app.Activity;
import android.util.Log;

import java.util.LinkedList;
import java.util.List;

public class ActivityCache {

    public static List<Activity> activityList = new LinkedList<Activity>();

    public ActivityCache() {

    }

    /**
     * 添加到Activity容器中
     */
    public static void addActivity(Activity activity) {
        if (!activityList.contains(activity)) {
            activityList.add(activity);
        }
        Log.d(
                "@@AfterAddActivity",
                Integer.toString(activityList.size())
        );
    }

    /**
     * 从堆栈中移除指定 Activity
     * @param activity
     */
    public static void removeActivity(Activity activity) {
        for(int i=0; i<activityList.size(); i++) {
            Activity activityItem = activityList.get(i);
            if (activityItem == activity) {
                activityList.remove(activity);
            }
        }
        Log.d(
                "@@AfterRemoveActivity",
                Integer.toString(activityList.size())
        );
    }

    /**
     * 返回上一个界面
     */
    public static void back() {
        if (activityList.size() <= 1) {
            return;
        }

        activityList.get(activityList.size() - 1).finish();
    }


    /**
     * 返回主界面
     */
    public static void backHome() {
        List<Activity> activityListCache = new LinkedList<Activity>();
        for (Activity activity : activityList) {
            activityListCache.add(activity);
        }

        for(int i=0; i<activityListCache.size(); i++) {
            if (i==0) {
                continue;
            }
            Activity activityItem = activityListCache.get(i);
            activityItem.finish();
        }
    }

    /**
     * 遍历所有Activigty并finish
     * @param currentActivity
     */
    public static void finishActivity(Activity currentActivity) {
        for (Activity activity : activityList) {
            activity.finish();
        }
    }

    /**
     * 结束指定的Activity
     */
    public static void finishSingleActivity(Activity activity) {
        if (activity != null) {
            if (activityList.contains(activity)) {
                activityList.remove(activity);
            }
            activity.finish();
            activity = null;
        }
    }

    /**
     * 结束指定类名的Activity 在遍历一个列表的时候不能执行删除操作，所有我们先记住要删除的对象，遍历之后才去删除。
     */
    public static void finishSingleActivityByClass(Class<?> cls) {
        Activity tempActivity = null;
        for (Activity activity : activityList) {
            if (activity.getClass().equals(cls)) {
                tempActivity = activity;
            }
        }

        finishSingleActivity(tempActivity);
    }

    /**
     * 重载最新的 activity
     */
    public static void reloadTopActivity() {
        if (activityList.size() == 0) {
            return;
        }

        Activity topActivity = activityList.get(activityList.size() - 1);
        if(topActivity instanceof RCTActivity) {
            ((RCTActivity) topActivity).reload();
        }

    }

    /**
     * 退出应用 / finish 所有 activity
     * 使用场景：切换国内、国外环境时使用
     */
    public static void exit() {
        List<Activity> activityListCache = new LinkedList<Activity>();
        for (Activity activity : activityList) {
            activityListCache.add(activity);
        }

        for(int i=0; i<activityListCache.size(); i++) {
            Activity activityItem = activityListCache.get(i);
            activityItem.finish();
        }
    }

    public static void ready() {
        if (activityList.size() == 0) {
            return;
        }

        Activity topActivity = activityList.get(activityList.size() - 1);
        if(topActivity instanceof RCTActivity) {
            ((RCTActivity) topActivity).ready();
        }

    }

}

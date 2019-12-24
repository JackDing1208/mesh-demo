package com.application;

import android.content.SharedPreferences;

/**
 * 应用持久化配置参数管理类
 */
public class ApplicationPreferencesManager {

    private static final String PREFS_NAME = "ApplicationPrefsFile";
    // DeveloperMode
    private static final String PREFS_KEY_DEVELOPERMODE = "DeveloperMode"; // 面板开发者模式，默认应为 false
    private static final Boolean PREFS_KEY_DEVELOPERMODE_DEFAULT_VALUE = false;

    public ApplicationPreferencesManager() {}

    /**
     * 初始化应用配置
     */
    public static void initPreferences() {
        /*
        SharedPreferences settings = MainApplication.getApplication().getSharedPreferences(PREFS_NAME, 0);
        SharedPreferences.Editor editor = settings.edit();
        editor.putBoolean(PREFS_KEY_DEVELOPERMODE, false);
        editor.commit();
        */
    }

    public static void setDeveloperMode(Boolean targetMode) {
        SharedPreferences settings = MainApplication.getApplication().getSharedPreferences(PREFS_NAME, 0);
        SharedPreferences.Editor editor = settings.edit();
        editor.putBoolean(PREFS_KEY_DEVELOPERMODE, targetMode);
        editor.commit();
    }

    public static Boolean getDeveloperMode() {
        SharedPreferences settings = MainApplication.getApplication().getSharedPreferences(PREFS_NAME, 0);
        return settings.getBoolean(PREFS_KEY_DEVELOPERMODE, PREFS_KEY_DEVELOPERMODE_DEFAULT_VALUE);
    }

    /**
     * 重置所有应用相关配置
     */
    public static void recoverAllPreferences() {
        SharedPreferences settings = MainApplication.getApplication().getSharedPreferences(PREFS_NAME, 0);
        SharedPreferences.Editor editor = settings.edit();
        editor.putBoolean(PREFS_KEY_DEVELOPERMODE, PREFS_KEY_DEVELOPERMODE_DEFAULT_VALUE);
        editor.commit();
    }
}

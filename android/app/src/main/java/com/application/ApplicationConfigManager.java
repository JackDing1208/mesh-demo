package com.application;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class ApplicationConfigManager {
    public static final String PREFS_NAME = "ApplicationConfig";
    public static final String PREFS_KEY_ENVIRONMENTKEY = "environmentKey";
    private volatile static ApplicationConfigManager instance;
    private ApplicationConfigManager (){};
    private Context mContext;
    private JSONObject mConfig;

    public static ApplicationConfigManager getInstance() {
        if (instance == null) {
            synchronized (ApplicationConfigManager.class) {
                if (instance == null) {
                    instance = new ApplicationConfigManager();
                }
            }
        }
        return instance;
    }

    public void setupContext(Context context) {
        if (mContext == null) {
            mContext = context;
            loadApplicationConfig(); // TODO: fix this
        }
    }

    public JSONObject getConfigData() {
        return this.mConfig;
    }

    public Map<String, Object> getConfigObject() {
        Map<String, Object> retMap = new Gson().fromJson(
                getConfigData().toString(),
                new TypeToken<HashMap<String, Object>>() {}.getType()
        );
        return retMap;
    }

    public void loadApplicationConfig() {
        String currentEnvironmentKey = getCurrentEnvironemntKey();
        String configFilePathInAssets = String.format("environment/applicationConfig_%s.json", currentEnvironmentKey);
        String configData = readJSONFromAsset(configFilePathInAssets);
        try {
            JSONObject config = new JSONObject(configData);
            mConfig = config;
            Log.d("@applicationConfig","loadApplicationConfig: "+config.toString());
        } catch (Exception error) {
            Log.e("@applicationConfig", "loadApplicationConfig error: "+error.toString());
        }
    }

    public String readJSONFromAsset(String filePathInAssets) {
        String json = null;
        try {
            InputStream is = mContext.getAssets().open(filePathInAssets);
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();
            json = new String(buffer, "UTF-8");
        } catch (IOException ex) {
            ex.printStackTrace();
            return null;
        }
        return json;
    }

    /**
     * 获取当前环境配置 key
     * @return {string}
     */
    public String getCurrentEnvironemntKey() {
        SharedPreferences settings = PreferenceManager.getDefaultSharedPreferences(mContext);
        String currentEnvironemntKey = settings.getString(PREFS_KEY_ENVIRONMENTKEY, "prod");
        Log.e("@applicationConfig", "currentEnvironemntKey: "+currentEnvironemntKey);
        return currentEnvironemntKey;
    }

    /**
     * 修改环境配置 Key
     * @param targetEnvironmentKey {string}
     */
    public Boolean setCurrentEnvironmentKey(String targetEnvironmentKey) {
        // 检查环境配置文件是否存在
        String targetApplicationConfigJSONFileName = String.format("applicationConfig_%s.json", targetEnvironmentKey);
        String targetSecurityImageFileName = String.format("yw_1222_%s", targetEnvironmentKey);
        try {
            // 检查 applicationConfig_{environmentKey}.json 文件是否存在
            Boolean applicationConfigJSONFileExists = Arrays.asList(mContext.getAssets().list("environment")).contains(targetApplicationConfigJSONFileName);
            if (!applicationConfigJSONFileExists) {
                Log.d("@targetJSONFileExists", "");
                return false;
            }
            // 检查对应安全图片文件是否存在
            Boolean securityImageFileExists = mContext.getResources().getIdentifier(targetSecurityImageFileName, "drawable", mContext.getPackageName()) != 0;
            if (!securityImageFileExists) {
                Log.d("@targetImageFileExists", "");
                return false;
            }
        } catch (Exception error) {
            Log.e("@applicationConfig", "setCurrentEnvironmentKey check file error: "+error.toString());
            return false;
        }

        // 确认环境配置文件存在，更新环境配置

        SharedPreferences settings = PreferenceManager.getDefaultSharedPreferences(mContext);
        SharedPreferences.Editor editor = settings.edit();
        editor.putString(PREFS_KEY_ENVIRONMENTKEY, targetEnvironmentKey);
        editor.commit();
        return true;
    }

    public String getAppID() {
        try {
            return mConfig.getJSONObject("accountServer").getString("id");
        } catch (Exception error) {
            Log.e("@applicationConfig", "getAppID error: "+error.toString());
            return "sim";
        }
    }

    public String getServerURL() {
        try {
            JSONObject AccountServerJSONObject = mConfig.getJSONObject("accountServer");
            String protocol = AccountServerJSONObject.getString("protocol");
            String host = AccountServerJSONObject.getString("host");
            int port = AccountServerJSONObject.getInt("port");
            String serverURL = String.format("%s://%s:%d", protocol, host, port);
            return serverURL;
        } catch (Exception error) {
            Log.e("@applicationConfig", "getAppID error: "+error.toString());
            return "http://localhost:8081";
        }
    }

    public String getAppKey() {
        try {
            return mConfig.getJSONObject("app").getJSONObject("appKey").getString("Android");
        } catch (Exception error) {
            Log.e("@applicationConfig", "getAppKey error: "+error.toString());
            return "00000000";
        }
    }
}

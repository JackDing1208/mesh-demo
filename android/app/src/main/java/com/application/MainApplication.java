package com.application;

import android.app.Application;
import android.content.Context;
import android.util.Log;

import com.facebook.react.PackageList;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.soloader.SoLoader;
import java.lang.reflect.InvocationTargetException;
import java.util.List;

public class MainApplication extends Application {

  private static Application sApplication;

  public static Application getApplication() {
    return sApplication;
  }

  public static Context getContext() {
    return getApplication().getApplicationContext();
  }

  @Override
  public void onCreate() {
    super.onCreate();
    SoLoader.init(this, /* native exopackage */ false);
    // initializeFlipper(this); // Remove this line if you don't want Flipper enabled

    // 初始化 applicationConfigManager
    ApplicationConfigManager.getInstance().setupContext(this);

    String currentEnvironmentKey = ApplicationConfigManager.getInstance().getCurrentEnvironemntKey();
    String appId = ApplicationConfigManager.getInstance().getAppID();
    String appKey = ApplicationConfigManager.getInstance().getAppKey();
    String baseHostURL = ApplicationConfigManager.getInstance().getServerURL();

    Log.d("@@debug","currentEnvironmentKey: "+currentEnvironmentKey);
    Log.d("@@debug", "appId: "+appId);
    Log.d("@@debug", "appKey: "+appKey);
    Log.d("@@debug", "baseHostURL: "+baseHostURL);

    sApplication = this;
  }

  /**
   * Loads Flipper in React Native templates.
   *
   * @param context
   */
  private static void initializeFlipper(Context context) {
    if (BuildConfig.DEBUG) {
      try {
        /*
         We use reflection here to pick up the class that initializes Flipper,
        since Flipper library is not available in release mode
        */
        Class<?> aClass = Class.forName("com.facebook.flipper.ReactNativeFlipper");
        aClass.getMethod("initializeFlipper", Context.class).invoke(null, context);
      } catch (ClassNotFoundException e) {
        e.printStackTrace();
      } catch (NoSuchMethodException e) {
        e.printStackTrace();
      } catch (IllegalAccessException e) {
        e.printStackTrace();
      } catch (InvocationTargetException e) {
        e.printStackTrace();
      }
    }
  }
}

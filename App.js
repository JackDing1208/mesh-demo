/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  TouchableOpacity,
  NativeModules
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
  DebugInstructions,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';

import ApplicationManager from "./app/applicationManager";
const applicationManager = new ApplicationManager()
global.applicationManager = applicationManager

const BLEMeshModule = NativeModules.BLEMeshModule
global.BLEMeshModule = NativeModules.BLEMeshModule

const LoadPageButton = () => {

  const loadNewPage = () => {
    let config = {
      online: true,
      host: "localhost",
      port: "8088",
      applicationName: "application",
      moduleName: "application", // todo: 修改为 main，需修改对应的面板包
      config: {
        type: "progress",
        iotId: "",
        model: "",
      },
      package: {}
    }

    applicationManager.loadPageWithOptions(config)
  }

  const style = {
    container: {
      padding: 20,
      backgroundColor: "#ff6600",
    },
    title: {
      color: "#ffffff",
    },
  }

  return (
    <TouchableOpacity style={style.container} onPress={loadNewPage}>
      <Text style={style.title}>LoadNewPage</Text>
    </TouchableOpacity>
  )
}

const Button = (props) => {

  const onPress = props.onPress
  const title = props.title || "Default Title"

  const style = {
    container: {
      padding: 20,
      backgroundColor: "#ff6600",
    },
    title: {
      color: "#ffffff",
    },
  }

  return (
    <TouchableOpacity style={style.container} onPress={onPress}>
      <Text style={style.title}>{title}</Text>
    </TouchableOpacity>
  )
}

const App: () => React$Node = (props) => {

  console.log(props)

  const Buttons = [
    <LoadPageButton key="load_button" />,
    <Button key="a" title="BLEMeshModule.a()" onPress={()=>{
      // alert("a()")
      BLEMeshModule.a()
    }} />,
    <Button key="test" title="BLEMeshModule.test()" onPress={() => {
      BLEMeshModule.test({ content: "Hello, world!" }, function (res) {
        console.log("@res", res)
      })
    }} />,
  ]

  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          style={styles.scrollView}>
          <Header />
          {Buttons}
          {global.HermesInternal == null ? null : (
            <View style={styles.engine}>
              <Text style={styles.footer}>Engine: Hermes</Text>
            </View>
          )}
          <View style={styles.body}>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Step One</Text>
              <Text style={styles.sectionDescription}>
                Edit <Text style={styles.highlight}>App.js</Text> to change this
                screen and then come back to see your edits.
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>See Your Changes</Text>
              <Text style={styles.sectionDescription}>
                <ReloadInstructions />
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Debug</Text>
              <Text style={styles.sectionDescription}>
                <DebugInstructions />
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Learn More</Text>
              <Text style={styles.sectionDescription}>
                Read the docs to discover what to do next:
              </Text>
            </View>
            <LearnMoreLinks />
          </View>
        </ScrollView>
      </SafeAreaView>
    </>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
});

export default App;

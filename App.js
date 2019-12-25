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
  NativeModules,
  SectionList,
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

const BLEMeshModule = NativeModules.BLEMesh
global.BLEMeshModule = NativeModules.BLEMesh

const Button = (props) => {

  const onPress = props.onPress
  const title = props.title || "Default Title"

  const style = {
    container: {
      padding: 20,
      backgroundColor: "#ffffff",
      borderBottomWidth: 1,
      borderBottomColor: "rgba(0,0,0,0.1)",
    },
    title: {
      color: "#000000",
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

  const list = (
    <SectionList
      style={{ flexGrow: 1, height: "100%" }}
      contentContainerStyle={{ flexGrow: 1 }}
      renderItem={({ item, index, section }) => (
        <Button key={`${section}_${index}`} title={item.title} onPress={item.onPress} />
      )}
      renderSectionHeader={({ section: { title } }) => (
        <Text style={{ fontWeight: "bold", padding: 20, backgroundColor: "#f4f4f4" }}>{title}</Text>
      )}
      sections={[
        {
          title: "面板分离", 
          data: [
            {
              title: "加载新面板",
              onPress: () => {
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
            },
            {
              title: "返回上一个面板",
              onPress: ()=>{
                applicationManager.back && applicationManager.back()
              }
            },
          ]
        },
        {
          title: "蓝牙 mesh",
          data: [
            {
              title: "setup()",
              onPress: () => {
                BLEMeshModule.setup()
              },
            },
            {
              title: "getAllNetworkKeys()",
              onPress: () => {
                BLEMeshModule.getAllNetworkKeys()
              },
            }
          ]
        }
      ]}
      keyExtractor={(item, index) => item + index}
    />
  )

  return (
    <View style={{ flex: 1, flexDirection: "column" }}>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        {list}
      </SafeAreaView>
    </View>
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

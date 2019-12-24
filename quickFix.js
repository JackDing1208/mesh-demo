// https://github.com/facebook/react-native/issues/26285

const rnVersion = function() {
    const rnPackageJson = require('./node_modules/react-native/package.json');
    return rnPackageJson.version;
  }();
  
  function patchHermesLocationForRN60Android() {
    const semver = require('semver');
    const fs = require('fs-extra');
  
    if (semver.minor(rnVersion) === 60 || semver.minor(rnVersion) === 61) {
      const HERMES_PATH_ROOT = './node_modules/hermesvm';
      const HERMES_PATH_RN = './node_modules/react-native/node_modules/hermesvm';
  
      const hermesIsInRoot = fs.existsSync(HERMES_PATH_ROOT);
      const hermesIsInRN = fs.existsSync(HERMES_PATH_RN);
  
      if (hermesIsInRoot && !hermesIsInRN) {
        fs.ensureDirSync(`${HERMES_PATH_RN}/android/`);
        fs.copySync(`${HERMES_PATH_ROOT}/android`, `${HERMES_PATH_RN}/android`);
      }
    }
  }
  patchHermesLocationForRN60Android();
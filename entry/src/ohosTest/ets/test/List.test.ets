import BluetoothPageTest from './BluetoothPage.test'
import WebDecodeServiceTest from './WebDecodeService.test'
import IndexPageTest from './IndexPage.test'
import LoginPageTest from './LoginPage.test'
import IndexTest from './Index.test'
import abilityTest from './Ability.test';
import FeedbackPageTest from './FeedbackPage.test';
import LanguageSettingPageTest from './LanguageSettingPage.test';
import SettingsPageTest from './SettingsPage.test';
import AboutAppPageTest from './AboutAppPage.test';

export default function testsuite() {
  abilityTest();
  IndexTest()
  FeedbackPageTest()
  LoginPageTest()
  IndexPageTest()
  WebDecodeServiceTest()
  LanguageSettingPageTest()
  SettingsPageTest()
  AboutAppPageTest()
  BluetoothPageTest()
}
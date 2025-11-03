import FeedbackPageTest from '../ohosTest/ets/test/FeedbackPage.test'
import LoginPageTest from './LoginPage.test'
import IndexTest from './Index.test'
import localUnitTest from './LocalUnit.test';

export default function testsuite() {
  localUnitTest();
  IndexTest()
  FeedbackPageTest()
  LoginPageTest()
}
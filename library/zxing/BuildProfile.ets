/**
 * Use these variables when you tailor your ArkTS code. They must be of the const type.
 */
export const HAR_VERSION = '2.1.0';
export const BUILD_MODE_NAME = 'release';
export const DEBUG = false;
export const TARGET_NAME = 'default';
export const MAIN_SERVER = 'https://baoshencode.gzbsit.com:10008';
export const PRODUCT_SERVER = 'https://baoshencode.gzbsit.com:10008/AppService';
export const QC_LOGIN = '/api/user/qcLogin';
export const USER_LOGIN = '/api/user/productInformationLogin';
export const Privacy = 'https://baoshencode.gzbsit.com:10008/Privacy.html';
export const Contract = 'https://baoshencode.gzbsit.com:10008/Contract.html';
export const OfficialWebsiteUrl = 'http://www.gzbsn.com/';
export const APPLICATION_ID = 'com.baoshen.hiddencode.app';
export const CopyrightYear = '2025';
export const RecordNumber = '';
export const UsingSplashPage = true;
export const BLE_MODE = true;

/**
 * BuildProfile Class is used only for compatibility purposes.
 */
export default class BuildProfile { 
	static readonly HAR_VERSION = HAR_VERSION;
	static readonly BUILD_MODE_NAME = BUILD_MODE_NAME;
	static readonly DEBUG = DEBUG;
	static readonly TARGET_NAME = TARGET_NAME;
	static readonly MAIN_SERVER = MAIN_SERVER;
	static readonly PRODUCT_SERVER = PRODUCT_SERVER;
	static readonly QC_LOGIN = QC_LOGIN;
	static readonly USER_LOGIN = USER_LOGIN;
	static readonly Privacy = Privacy;
	static readonly Contract = Contract;
	static readonly OfficialWebsiteUrl = OfficialWebsiteUrl;
	static readonly APPLICATION_ID = APPLICATION_ID;
	static readonly CopyrightYear = CopyrightYear;
	static readonly RecordNumber = RecordNumber;
	static readonly UsingSplashPage = UsingSplashPage;
	static readonly BLE_MODE = BLE_MODE;
}
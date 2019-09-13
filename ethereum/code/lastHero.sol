pragma solidity ^0.4.20; // ����汾

/*
* LastHero�Ŷ�.
* -> ����ʲô?
* �Ľ��������������ʽ�ģ��:
* [x] �ú�Լ��Ŀǰ���ȶ������ܺ�Լ�����ܹ����еĹ�������!
* [x] ��ARC�ȶ�����ȫר����˲��ԡ�
* [X] �¹��ܣ��ɲ��������������ؽ���������ʲ�ȫ������!
* [x] �¹��ܣ�������Ǯ��֮�䴫����ҡ����������ܺ�Լ�н��н���!
* [x] �����ԣ������״�POS�ڵ���̫��ְ�ܺ�Լ����V������¹��ܡ�
* [x] ���ڵ㣺����100�����Ҽ���ӵ���Լ������ڵ㣬���ڵ���Ψһ�����ܺ�Լ���!
* [x] ���ڵ㣺����ͨ��������ڵ�����Լ����ң�����Ի��10%�ķֺ�!
*
* -> ������Ŀ?
* ���ǵ��Ŷӳ�Աӵ�г�ǿ�Ĵ�����ȫ���ܺ�Լ��������
* �µĿ����Ŷ��ɾ���ḻ��רҵ������Ա��ɣ����������Լ��ȫר����ˡ�
* ���⣬���ǹ������й����ٴε�ģ�⹥�����ú�Լ����û�б����ƹ���
* 
* -> �����Ŀ�ĳ�Ա����Щ?
* - PonziBot (math/memes/main site/master)��ѧ
* - Mantso (lead solidity dev/lead web3 dev)����
* - swagg (concept design/feedback/management)�������/����/����
* - Anonymous#1 (main site/web3/test cases)��վ/web3/����
* - Anonymous#2 (math formulae/whitepaper)��ѧ�Ƶ�/��Ƥ��
*
* -> ����Ŀ�İ�ȫ�����Ա:
* - Arc
* - tocisck
* - sumpunk
*/

contract Hourglass {
/*=================================
= MODIFIERS ȫ�� =
=================================*/
// ֻ�޳ֱ��û�
modifier onlyBagholders() {
require(myTokens() > 0);
_;
}
// ֻ�������û�
modifier onlyStronghands() {
require(myDividends(true) > 0);
_;
}
// ����ԱȨ��:
// -> ���ĺ�Լ����
// -> ���Ĵ�������
// -> �ı�POS���Ѷȣ�ȷ��ά��һ�����ڵ���Ҫ���ٴ��ң��Ա����ķ���
// ����Աû��Ȩ������������:
// -> �����ʽ�
// -> ��ֹ�û�ȡ��
// -> �Իٺ�Լ
// -> �ı���Ҽ۸�
modifier onlyAdministrator(){ // ����ȷ���ǹ���Ա
address _customerAddress = msg.sender;
require(administrators[keccak256(_customerAddress)]); // �ڹ���Ա�б��д���
_; // ��ʾ��modifier�ĺ���ִ����󣬿�ʼִ����������
}
// ȷ����Լ�е�һ�����Ҿ��ȵķ���
// ����ζ�ţ�����ƽ�����Ƴɱ��ǲ����ܴ��ڵ�
// �⽫Ϊ����Ľ����ɳ����¼�ʵ�Ļ�����
modifier antiEarlyWhale(uint256 _amountOfEthereum){ // �ж�״̬
address _customerAddress = msg.sender;
// ���ǻ��Ǵ��ڲ�����Ͷ�ʵ�λ��?
// ��Ȼ��ˣ����ǽ���ֹ���ڵĴ��Ͷ�� 
if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
require(
// ����û��ڴ���������
ambassadors_[_customerAddress] == true &&
// �û��������Ƿ񳬹�����������
(ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
);
// �����ۼ���� 
ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
// ִ��
_;
} else {
// �����������̫�������½�������ֵ������׶�Ҳ��������������
onlyAmbassadors = false;
_; 
}
}
/*==============================
= EVENTS �¼� =
==============================*/
event onTokenPurchase( // �������
address indexed customerAddress,
uint256 incomingEthereum,
uint256 tokensMinted,
address indexed referredBy
);
event onTokenSell( // ���۴���
address indexed customerAddress,
uint256 tokensBurned,
uint256 ethereumEarned
);
event onReinvestment( // ��Ͷ��
address indexed customerAddress,
uint256 ethereumReinvested,
uint256 tokensMinted
);
event onWithdraw( // ��ȡ�ʽ�
address indexed customerAddress,
uint256 ethereumWithdrawn
);
// ERC20��׼
event Transfer( // һ�ν���
address indexed from,
address indexed to,
uint256 tokens
);
/*=====================================
= CONFIGURABLES ���� =
=====================================*/
string public name = "LastHero3D"; // ����
string public symbol = "Keys"; // ����
uint8 constant public decimals = 18; // С��λ
uint8 constant internal dividendFee_ = 10; // ���׷ֺ����
uint256 constant internal tokenPriceInitial_ = 0.0000001 ether; // ���ҳ�ʼ�۸�
uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether; // ���ҵ����۸�
uint256 constant internal magnitude = 2**64;
// �ɷ�֤����Ĭ��ֵΪ100���ң�
uint256 public stakingRequirement = 100e18;
// ����ƻ�
mapping(address => bool) internal ambassadors_; // ������
uint256 constant internal ambassadorMaxPurchase_ = 1 ether; // �����
uint256 constant internal ambassadorQuota_ = 20 ether; // �����޶�
/*================================
= DATASETS ���� =
================================*/
// ÿ����ַ�Ĺɷ���������������ţ�
mapping(address => uint256) internal tokenBalanceLedger_; // �����ַ�Ĵ�������
mapping(address => uint256) internal referralBalance_; // �����ַ���Ƽ��ֺ�
mapping(address => int256) internal payoutsTo_;
mapping(address => uint256) internal ambassadorAccumulatedQuota_;
uint256 internal tokenSupply_ = 0;
uint256 internal profitPerShare_;
// ����Ա�б�����ԱȨ�޼�������
mapping(bytes32 => bool) public administrators; // �����ߵ�ַ�б�
// �������ƶȳ�����ֻ�д�����Թ�����ң���ȷ���������Ľ������ֲ����Է��ֱұ���������
bool public onlyAmbassadors = true; // ����ֻ�д����ܹ��������

/*=======================================
= PUBLIC FUNCTIONS �������� =
=======================================*/
/*
* -- Ӧ����� -- 
*/
function Hourglass()
public
{
// ��������ӹ���Ա
administrators[0xb3cefeaeb0dc79342a0ff55932e3327c2f75ceeb0e395eea1a1b09db60aa9573] = true;
// ��������Ӵ���
// mantso - lead solidity dev & lead web dev. 
ambassadors_[0x24257cF6fEBC8aAaE2dC20906d4Db1C619d40329] = true;
// ponzibot - mathematics & website, and undisputed meme god.
ambassadors_[0xEa01f6203bD55BA694594FDb5575f2936dB7f698] = true;
// swagg - concept design, feedback, management.
ambassadors_[0x22caa6670991D67bf0EA033156114F07de4aa20b] = true;
// k-dawgz - shilling machine, meme maestro, bizman.
ambassadors_[0xC68538d6971D1B0AC8829f8B14e6a9B2AF614119] = true;
// elmojo - all those pretty .GIFs & memes you see? you can thank this man for that.
ambassadors_[0x23183DaFd738FB876c363dA7651A679fcb24b657] = true;
// capex - community moderator.
ambassadors_[0x95E8713a5D2bf0DDAf8D0819e73907a8CEE3D111] = true;
// j?rmungandr - pentests & twitter trendsetter.
ambassadors_[0x976f6397ae155239289D6cb7904E6730BeBa7c79] = true;
// inventor - the source behind the non-intrusive referral model.
ambassadors_[0xA732E7665fF54Ba63AE40E67Fac9f23EcD0b1223] = true;
// tocsick - pentesting, contract auditing.
ambassadors_[0x445b660236c39F5bc98bc49ddDc7CF1F246a40aB] = true;
// arc - pentesting, contract auditing.
ambassadors_[0x60e31B8b79bd92302FE452242Ea6F7672a77a80f] = true;
// sumpunk - contract auditing.
ambassadors_[0xbbefE89eBb2a0e15921F07F041BE5691d834a287] = true;
// randall - charts & sheets, data dissector, advisor.
ambassadors_[0x5ad183E481cF0477C024A96c5d678a88249295b8] = true;
// ambius - 3d chart visualization.
ambassadors_[0x10C5423A46a09D6c5794Cdd507ee9DA7E406F095] = true;
// contributors that need to remain private out of security concerns.
ambassadors_[0x9E191643D643AA5908C5B9d3b10c27Ad9fb4AcBE] = true; //dp
ambassadors_[0x2c389a382003E9467a84932E68a35cea27A34B8D] = true; //tc
ambassadors_[0x924E71bA600372e2410285423F1Fe66799b717EC] = true; //ja
ambassadors_[0x6Ed450e062C20F929CB7Ee72fCc53e9697980a18] = true; //sf
ambassadors_[0x18864A6682c8EB79EEA5B899F11bC94ef9a85ADb] = true; //tb
ambassadors_[0x9cC1BdC994b7a847705D19106287C0BF94EF04B5] = true; //sm
ambassadors_[0x6926572813ec1438088963f208C61847df435a74] = true; //mc
ambassadors_[0xE16Ab764a02Ae03681E351Ac58FE79717c0eE8C6] = true; //et
ambassadors_[0x276F4a79F22D1BfC51Bd8dc5b27Bfd934C823932] = true; //sn
ambassadors_[0xA2b4ed3E2f4beF09FB35101B76Ef4cB9D3eeCaCf] = true; //bt
ambassadors_[0x147fc6b04c95BCE47D013c8d7a200ee434323669] = true; //al

}
/**
* ��������̫�����紫��ת��Ϊ���ҵ��ã������´��ݣ�������²����ˣ�
*/
function buy(address _referredBy)
public
payable
returns(uint256)
{
purchaseTokens(msg.value, _referredBy);
}
/**
* �ص�����������ֱ�ӷ��͵���Լ����̫��������
* ���ǲ���ͨ�����ַ�ʽ��ָ��һ����ַ��
*/
function()
payable
public
{
purchaseTokens(msg.value, 0x0);
}
/**
* �����еķֺ�����ת��Ϊ���ҡ�
*/
function reinvest()
onlyStronghands()
public
{
// ��ȡ��Ϣ
uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
// ʵ��֧���Ĺ�Ϣ
address _customerAddress = msg.sender;
payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
// �����ο�����
_dividends += referralBalance_[_customerAddress];
referralBalance_[_customerAddress] = 0;
// ����һ�����򶩵�ͨ�����⻯�ġ����ع�Ϣ��
uint256 _tokens = purchaseTokens(_dividends, 0x0);
// �ش��¼�
onReinvestment(_customerAddress, _dividends, _tokens);
}
/**
* �˳����̣�����������ȡ�ʽ�
*/
function exit()
public
{
// ͨ�����û�ȡ��������������ȫ������
address _customerAddress = msg.sender;
uint256 _tokens = tokenBalanceLedger_[_customerAddress];
if(_tokens > 0) sell(_tokens);
// ȡ�����
withdraw();
}

/**
* ȡ�������ߵ��������档
*/
function withdraw()
onlyStronghands()
public
{
// ��������
address _customerAddress = msg.sender;
uint256 _dividends = myDividends(false); // �Ӵ����л�òο�����
// ���¹�Ϣϵͳ
payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
// ��Ӳο�����
_dividends += referralBalance_[_customerAddress];
referralBalance_[_customerAddress] = 0;
// ��ȡ����
_customerAddress.transfer(_dividends);
// �ش��¼�
onWithdraw(_customerAddress, _dividends);
}
/**
* ��̫�����ҡ�
*/
function sell(uint256 _amountOfTokens)
onlyBagholders()
public
{
// ��������
address _customerAddress = msg.sender;
// ���Զ���˹��BTFO
require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
uint256 _tokens = _amountOfTokens;
uint256 _ethereum = tokensToEthereum_(_tokens);
uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
// �����ѳ��۵Ĵ���
tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
// ���¹�Ϣϵͳ
int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
payoutsTo_[_customerAddress] -= _updatedPayouts; 
// ��ֹ����0
if (tokenSupply_ > 0) {
// ���´��ҵĹ�Ϣ���
profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
}
// �ش��¼�
onTokenSell(_customerAddress, _tokens, _taxedEthereum);
}
/**
* ���������˻�ת�ƴ����³������˻���
* ��ס�����ﻹ��10%�ķ��á�
*/
function transfer(address _toAddress, uint256 _amountOfTokens)
onlyBagholders()
public
returns(bool)
{
// ����
address _customerAddress = msg.sender;
// ȡ��ӵ���㹻�Ĵ���
// ���ҽ�ֹת�ƣ�ֱ������׶ν�����
// �����ǲ��벶����
require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
// ȡ������δ���Ĺ�Ϣ
if(myDividends(true) > 0) withdraw();
// ��ת�ƴ��ҵ�ʮ��֮һ
// ��Щ����ƽ�ָ����ɶ�
uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
uint256 _dividends = tokensToEthereum_(_tokenFee);
// ���ٷ��ô���
tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

// ���ҽ���
tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
// ���¹�Ϣϵͳ
payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
// �ַ���Ϣ��������
profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
// �ش��¼�
Transfer(_customerAddress, _toAddress, _taxedTokens);
// ERC20��׼
return true;
}
/*---------- ����Ա���� ----------*/
/**
* ���û������������Ա������ǰ��������׶Ρ�
*/
function disableInitialStage()
onlyAdministrator()
public
{
onlyAmbassadors = false;
}
/**
* ��������������Ը�������Ա�˻���
*/
function setAdministrator(bytes32 _identifier, bool _status)
onlyAdministrator()
public
{
administrators[_identifier] = _status;
}
/**
* ��ΪԤ����ʩ������Ա���Ե������ڵ�ķ��ʡ�
*/
function setStakingRequirement(uint256 _amountOfTokens)
onlyAdministrator()
public
{
stakingRequirement = _amountOfTokens;
}
/**
* ����Ա�������¶���Ʒ�ƣ��������ƣ���
*/
function setName(string _name)
onlyAdministrator()
public
{
name = _name;
}
/**
* ����Ա�������¶���Ʒ�ƣ����ҷ��ţ���
*/
function setSymbol(string _symbol)
onlyAdministrator()
public
{
symbol = _symbol;
}

/*---------- �����ߺͼ����� ----------*/
/**
* �ں�Լ�в鿴��ǰ��̫��״̬�ķ���
* ���� totalEthereumBalance()
*/
function totalEthereumBalance() // �鿴���
public
view
returns(uint)
{
return this.balance;
}
/**
* �������ҹ�Ӧ������
*/
function totalSupply()
public
view
returns(uint256)
{
return tokenSupply_;
}
/**
* ���������ߵĴ�����
*/
function myTokens()
public
view
returns(uint256)
{
address _customerAddress = msg.sender; // ��÷����ߵĵ�ַ
return balanceOf(_customerAddress);
}
/**
* ȡ��������ӵ�еĹ�Ϣ��
* ���`_includeReferralBonus` ��ֵΪ1����ô�Ƽ����𽫱��������ڡ�
* ��ԭ���ǣ�����ҳ��ǰ�ˣ�����ϣ���õ�ȫ�ֻ��ܡ�
* �����ڲ������У�����ϣ���ֿ����㡣
*/ 
function myDividends(bool _includeReferralBonus) // ���طֺ���������Ĳ�������ָʾ�Ƿ����Ƽ��ֺ�
public 
view 
returns(uint256)
{
address _customerAddress = msg.sender;
return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
}
/**
* ���������ַ�Ĵ�����
*/
function balanceOf(address _customerAddress)
view
public
returns(uint256)
{
return tokenBalanceLedger_[_customerAddress];
}
/**
* ���������ַ�Ĺ�Ϣ��
*/
function dividendsOf(address _customerAddress)
view
public
returns(uint256)
{
return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
}
/**
* ���ش�������ļ۸�
*/
function sellPrice() 
public 
view 
returns(uint256)
{
// ���ǵļ��������ڴ��ҹ�Ӧ������������Ҫ֪����Ӧ����
if(tokenSupply_ == 0){
return tokenPriceInitial_ - tokenPriceIncremental_;
} else {
uint256 _ethereum = tokensToEthereum_(1e18);
uint256 _dividends = SafeMath.div(_ethereum, dividendFee_ );
uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
return _taxedEthereum;
}
}
/**
* ���ش��������ļ۸�
*/
function buyPrice() 
public 
view 
returns(uint256)
{
// ���ǵļ��������ڴ��ҹ�Ӧ������������Ҫ֪����Ӧ����
if(tokenSupply_ == 0){
return tokenPriceInitial_ + tokenPriceIncremental_;
} else {
uint256 _ethereum = tokensToEthereum_(1e18);
uint256 _dividends = SafeMath.div(_ethereum, dividendFee_ );
uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
return _taxedEthereum;
}
}
/**
* ǰ�˹��ܣ���̬��ȡ���붩���۸�
*/
function calculateTokensReceived(uint256 _ethereumToSpend) 
public 
view 
returns(uint256)
{
uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
return _amountOfTokens;
}
/**
* ǰ�˹��ܣ���̬��ȡ���������۸�
*/
function calculateEthereumReceived(uint256 _tokensToSell) 
public 
view 
returns(uint256)
{
require(_tokensToSell <= tokenSupply_);
uint256 _ethereum = tokensToEthereum_(_tokensToSell);
uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
return _taxedEthereum;
}
/*==========================================
= INTERNAL FUNCTIONS �ڲ����� =
==========================================*/
function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
antiEarlyWhale(_incomingEthereum)
internal
returns(uint256)
{
// ��������
address _customerAddress = msg.sender;
uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
uint256 _fee = _dividends * magnitude;
// ��ֹ����ִ��
// ��ֹ���
// (��ֹ�ڿ�����)
// ����SAFEMATH��֤���ݰ�ȫ��
require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
// �û��Ƿ����ڵ����ã�
if(
// �Ƿ����Ƽ��ߣ�
_referredBy != 0x0000000000000000000000000000000000000000 &&

// ��ֹ����!
_referredBy != _customerAddress && // �����Լ��Ƽ��Լ�
// �Ƽ����Ƿ����㹻�Ĵ��ң�
// ȷ���Ƽ����ǳ�ʵ�����ڵ�
tokenBalanceLedger_[_referredBy] >= stakingRequirement
){
// �Ƹ��ٷ���
referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
} else {
// ���蹺��
// ����Ƽ�������ȫ�ַֺ�
_dividends = SafeMath.add(_dividends, _referralBonus); // ���Ƽ����������ֺ�
_fee = _dividends * magnitude;
}
// ���ǲ��ܸ����޾�����̫��
if(tokenSupply_ > 0){
// ��Ӵ��ҵ����ҳ�
tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
// ��ȡ��ʽ�������õĹ�Ϣ������ƽ����������йɶ�
profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
// �����û�ͨ�������õĴ��������� 
_fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
} else {
// ��Ӵ��ҵ����ҳ�
tokenSupply_ = _amountOfTokens;
}
// ���´��ҹ�Ӧ�������û���ַ
tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
// ��������˫����ӵ�д���ǰ�����÷ֺ죻
// ��֪������Ϊ�����ˣ�������û������
int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
payoutsTo_[_customerAddress] += _updatedPayouts;
// �ش��¼�
onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
return _amountOfTokens;
}

/**
* ͨ����̫����������������Ҽ۸�
* ����һ���㷨���ڰ�Ƥ�������ҵ����Ŀ�ѧ�㷨��
* ����һЩ�޸ģ��Է�ֹʮ���ƴ���ʹ�������������
*/
function ethereumToTokens_(uint256 _ethereum) // ����ETH�һ����ҵĻ���
internal
view
returns(uint256)
{
uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
uint256 _tokensReceived = 
(
(
// �����������
SafeMath.sub(
(sqrt
(
(_tokenPriceInitial**2)
+
(2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
+
(((tokenPriceIncremental_)**2)*(tokenSupply_**2))
+
(2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
)
), _tokenPriceInitial
)
)/(tokenPriceIncremental_)
)-(tokenSupply_)
;
return _tokensReceived;
}
/**
* ������ҳ��۵ļ۸�
* ����һ���㷨���ڰ�Ƥ�������ҵ����Ŀ�ѧ�㷨��
* ����һЩ�޸ģ��Է�ֹʮ���ƴ���ʹ�������������
*/
function tokensToEthereum_(uint256 _tokens)
internal
view
returns(uint256)
{

uint256 tokens_ = (_tokens + 1e18);
uint256 _tokenSupply = (tokenSupply_ + 1e18);
uint256 _etherReceived =
(
// underflow attempts BTFO
SafeMath.sub(
(
(
(
tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
)-tokenPriceIncremental_
)*(tokens_ - 1e18)
),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
)
/1e18);
return _etherReceived;
}
//���������Gas
//���Ż������1gwei
function sqrt(uint x) internal pure returns (uint y) {
uint z = (x + 1) / 2;
y = x;
while (z < y) {
y = z;
z = (x / z + z) / 2;
}
}
}

/**
* @title SafeMath����
* @dev ��ȫ����ѧ����
*/
library SafeMath {

/**
* @dev �������ֳ˷����׳������
*/
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
assert(c / a == b);
return c;
}

/**
* @dev �������ֵ�����������
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // ֵΪ0ʱ�Զ��׳�
uint256 c = a / b;
// assert(a == b * c + a % b); // ���򲻳���
return c;
}

/**
* @dev �������ֵļ���������������ڱ�������������׳���
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

/**
* @dev �������ֵļӷ�����������׳�
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
assert(c >= a);
return c;
}
}

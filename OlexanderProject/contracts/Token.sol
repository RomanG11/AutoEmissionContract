pragma solidity ^0.4.20;
library SafeMath { //standard library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

contract Ownable { //standart contract to identify owner
  address public owner;
  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function Ownable() public {
    owner = msg.sender;
  }
  
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }
  
  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

contract ERC20Token is Ownable { //ERC - 20 token contract
  using SafeMath for uint;

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


  string public constant symbol = "TKN";
  string public constant name = "TOKEN";

  uint8 public constant decimals = 18;
  uint256 _totalSupply = 1000000000 ether;

  // Owner of this contract
  address public owner;
  // Balances for each account

  function ERC20Token () public {
    owner = msg.sender;
    balances[owner] = 1000000 ether;
    balances[address(this)] = _totalSupply - balances[owner]; 
    storages.push(Storage(0,0,false));
  }
  
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) { //standart ERC-20 function
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {//standart ERC-20 function
    return balances[_address];
  }

  //standart ERC-20 function
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender,_to,_amount);

    if(_to == address(this)){
      storeTokens(msg.sender,_amount,now);
    }

    return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);

    if(_to == address(this)){
      storeTokens(_from,_amount,now);
    }

    return true;
  }

  //standart ERC-20 function
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  //standart ERC-20 function
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => bool) accessMapping;
  
  // function burnTokens () returns(bool res) internal {
  //   require (accessMapping[msg.sender]);
        
  //   return true;
  // }
  
  struct Storage {
    uint balance;
    uint storageTime;
    bool notZero;
  }
  
  Storage[] public storages;
  
  mapping (address => uint[]) storagesMap;

  function getStorageMap (address _address) public view returns(uint[]) {
    return storagesMap[_address];
  }
  

  function storeTokens (address _address, uint _value, uint _time) internal {
    require (_value > 0);
    
    storages.push(Storage(_value,_time, true));
    storagesMap[_address].push(storages.length-1);
  }

  function getTokensBack (uint _value) public returns(bool) {
    require (storagesMap[msg.sender].length > 0);
    
    address _address = msg.sender;
    
    uint collectedTokens = 0;

    for (uint i = storagesMap[_address].length-1; i >= 0; i--){
      if(storagesMap[_address][i] != 0){
        if (storages[storagesMap[_address][i]].balance > _value - collectedTokens){
          storages[storagesMap[_address][i]].balance -= _value - collectedTokens;

          balances[this] -= _value;
          balances[msg.sender] += _value;
          emit Transfer(this, msg.sender, _value);
          return true;

        }else if (storages[storagesMap[_address][i]].balance == _value - collectedTokens){
          storages[storagesMap[_address][i]].balance = 0;
          storages[storagesMap[_address][i]].notZero = false;

          delete storagesMap[_address][i];

          balances[this] -= _value - collectedTokens;
          balances[msg.sender] += _value - collectedTokens;
          emit Transfer(this, msg.sender, _value);
          return true;

        }else{
          if(storages[storagesMap[_address][i]].notZero){
            collectedTokens += storages[storagesMap[_address][i]].balance;
            storages[storagesMap[_address][i]].balance = 0;
            storages[storagesMap[_address][i]].notZero = false;

            delete storagesMap[_address][i];
          }
        }  
      }
      if (i == 0){
        break;
      }
    }

    balances[this] -= collectedTokens;
    balances[msg.sender] += collectedTokens;

    emit Transfer(this,msg.sender, collectedTokens);

    return true;
  }

  function getStoreBalance (address _address) public view returns(uint res)  {
    for (uint i = 0; i < storagesMap[_address].length; i++){
      if(storagesMap[_address][i] != 0){
        res += storages[storagesMap[_address][i]].balance;
      }
    }
  }

  uint[] public activeElements;
  uint public startElement;

  function getActiveElements () public onlyOwner {
    startElement = activeElements.length-1;
    for (uint i = 0; i < storages.length; i++){
      if((storages[i].notZero) && (storages[i].storageTime + 8 weeks > now)){
        activeElements.push(i);
      }
    }
  }

  //1000 (0.1% accuracy)
  function changeStorageTokens (uint _value) public onlyOwner {
    for(uint i = startElement; i < activeElements.length; i++){
      if(storages[activeElements[i]].notZero){
        storages[activeElements[i]].balance = storages[activeElements[i]].balance.mul(_value)/1000; 
      }
    }
  }
  
  


  
  
  
}
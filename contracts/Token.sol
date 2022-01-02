pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ERC20Interface{
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
   
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Interface{

    string public name = "Baicoin";
    string public symbol = "BCN";
    uint public decimals = 0;
    uint public override totalSupply;
    address public founder;

    mapping (address => uint) public balances;

    mapping (address => mapping(address => uint)) allowed;

    constructor(){ 
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public override returns  (bool success){
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        allowed[msg.sender][_spender] =  _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool success){
        require(balances[_from] >= _value, "Insufficient funds!");
        require(allowed[_from][_to] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;

        return true;
    }


    function balanceOf(address _owner) public view override returns (uint256 balance){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override virtual returns (bool success){
        require(balances[msg.sender] >= _value, "You don't have enough tokens!");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
}

contract ICO is Token{
    address public admin;
    address payable public deposit;

    uint tokenPrice = 0.001 ether;
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = saleStart + 1000;
    uint public tokenTradeStart = saleEnd + 1000;
    uint public minInvestment = 0.1 ether;
    uint public maxInvestment = 5 ether;

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    constructor(address payable _deposit){
        admin = msg.sender;
        deposit = _deposit;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "You must be the admin!");
        _;
    }

    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }

    function changeDeposit(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }

    function getIcoState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp > saleStart && block.timestamp < saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() public payable returns(bool){
        icoState = getIcoState();
        require(icoState == State.running, "ICO must be running to invest!");
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Investment must be in the valid range!");
        
        raisedAmount += msg.value;  
        require(raisedAmount < hardCap, "Hardcap has been reached!");
        
        uint tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;

        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    receive() external payable{
        invest();
    }

    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool success){
        require(block.timestamp > tokenTradeStart, "Tokens are locked");
        return Token.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(block.timestamp > tokenTradeStart, "Tokens are locked");
        return super.transfer(_to, _value);        
    }

    function burn() public returns(bool){
        icoState = getIcoState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }

    
}
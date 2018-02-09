pragma solidity ^0.4.2;

//@notice : blind auction contract
//@warning : this is not to be used in production

//@info: SimplePaymentAuth is a smart contract for managing subscription based
// logins to any authorization system
// Since we are simply storing hashes
import "./safeMath.sol";


contract FixedAmountSimplePaymentAuth {
    address public owner;
    bytes32 public siteName;
    bytes32 public feeCycle;
    uint256 public feeAmount;
    bool public ended;

    struct User {
        address loginUsername;
        bytes32 passHash;
        uint lastPaymentDate;
    }

    mapping(address => User) private users;
    mapping(address => uint256) private refunds;

    event NewUser();
    event RenewSubscription();
    event Ended();
    event FeeChanged();
    event CycleChanged();

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    modifier notEnded() {
        assert(!ended);
        _;
    }

    modifier sufficientFee() {
        assert(msg.value >= feeAmount);
        _;
    }

    modifier validPassword(bytes32 hash) {
        assert(hash.length == 26);
        _;
    }

    modifier onlyNewUser() {
        assert(users[msg.sender].loginUsername == 0);
        _;
    }

    modifier onlyExistingUser() {
        assert(users[msg.sender].loginUsername != 0);
        _;
    }

    function FixedAmountSimplePaymentAuth(uint256 feeAmt, bytes32 cycle, bytes32 name ) public {
        owner = msg.sender;
        feeAmount = feeAmt;
        siteName = name;
        feeCycle = cycle;
    }

    /**
    * @dev payable fallback
    */
    function () public payable {}

    function signUp(bytes32 passHash) public payable notEnded onlyNewUser sufficientFee validPassword(passHash) {
        uint256 extraAmount = SafeMath.sub(msg.value, feeAmount);
        users[msg.sender] = User({
            loginUsername: msg.sender,
            passHash: passHash,
            lastPaymentDate: block.timestamp
        });
        refunds[msg.sender] = extraAmount;
    }

    function renewSubscription() public payable notEnded onlyExistingUser sufficientFee {
        uint256 extraAmount = SafeMath.sub(msg.value, feeAmount);
        refunds[msg.sender] += extraAmount;
        users[msg.sender].lastPaymentDate = block.timestamp;
    }

    function withdrawRefund() public onlyExistingUser {
        assert(refunds[msg.sender] > 0);
        uint256 amt = refunds[msg.sender];
        refunds[msg.sender] = 0;
        msg.sender.transfer(amt);
    }

    function changePassword(bytes32 newPas) public notEnded onlyExistingUser {
        users[msg.sender].passHash = newPas;
    }

    function kill() public notEnded onlyOwner {
        ended = true;
    }

    function withdraw(uint256 amount, address to) public onlyOwner {
        assert(amount <= this.balance);
        to.transfer(amount);
    }
}

/* author： gaohtao@163.com */
pragma solidity >= 0.5.0 < 0.6.0;

//import "github.com/provable-things/ethereum-api/provableAPI.sol";
import "https://github.com/provable-things/ethereum-api/provableAPI_0.5.sol";

contract RandomExample is usingProvable {
    // Define variables
    uint public randomNumber; // number obtained from random.org

    uint256 constant MAX_INT_FROM_BYTE = 256;
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;

    event LogNewProvableQuery(string description);
    event generatedRandomNumber(uint256 randomNumber);

    constructor()  public  {
        
        provable_setProof(proofType_Ledger);
        // update();
    }

    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            /**
             * @notice  The proof verification has failed! Handle this case
             *          however you see fit.
             */
        } else {
            /**
             *
             * @notice  The proof verifiction has passed!
             *
             *          Let's convert the random bytes received from the query
             *          to a `uint256`.
             *
             *          To do so, We define the variable `ceiling`, where
             *          `ceiling - 1` is the highest `uint256` we want to get.
             *          The variable `ceiling` should never be greater than:
             *          `(MAX_INT_FROM_BYTE ^ NUM_RANDOM_BYTES_REQUESTED) - 1`.
             *
             *          By hashing the random bytes and casting them to a
             *          `uint256` we can then modulo that number by our ceiling
             *          in order to get a random number within the desired
             *          range of [0, ceiling - 1].
             *
             */
            uint256 ceiling = (MAX_INT_FROM_BYTE ** NUM_RANDOM_BYTES_REQUESTED) - 1;
            randomNumber = uint256(keccak256(abi.encodePacked(_result))) % ceiling;
            emit generatedRandomNumber(randomNumber);
        }
    }

    function update()
        payable
        public
    {
        uint256 QUERY_EXECUTION_DELAY = 0; // NOTE: The datasource currently does not support delays > 0!
        uint256 GAS_FOR_CALLBACK = 200000;
        provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }
}

contract Lottery10Users {
    RandomExample public rand;
    uint public randNonce =0;

    address payable[10] public participants;        //限制为10个用户
    uint8 public  participantsCount = 0;     //本轮已参与用户数
    uint public  winner = 0;   
    uint public time;  //奖池创建时间，单位秒  

    event winnerIndex(string, uint, address);  //中奖者序号及地址   

    constructor()  public  {        
       rand = new RandomExample();
       time = now;
    }     
 
    function join() public payable {
	    //用户必须支付 0.01 ETH 才能加入游戏
        require(msg.value == 0.01 ether, "Must send 0.01 ether");
        require(participantsCount < 10, "User limit reached");
        require(joinedAlready(msg.sender) == false, "User already joined");
		
        participants[participantsCount] = msg.sender;
		participantsCount++;
        
		//第10个用户进入后，选择获胜者
		// drawLottery();
    }

    //查询用户加入游戏状态，同一用户每轮只能加入一次
    function joinedAlready(address _participant) private view returns(bool) {
        bool find = false;
        for (uint i=0;i<participantsCount;i++){
           if(participants[i]==_participant)
               find = true;
        }
        return find;    
    }

    //开奖， 条件是10个人、间隔1小时，
    function drawLottery() public {
        require(participantsCount>0,"no player");
        require( participantsCount<10 && (time+3600)<now, "It's not drawing time");
        //开奖，选出中奖者序号
        selectWinner2();
        //发放奖励
        participants[winner].transfer(address(this).balance);
        //无需清空数组数据,计数器恢复为0就可以了
        participantsCount =0;   
        //更新下一轮的时间起点
        time = now;         
        
    }

    //真随机数，生成随机数花费0.05ETH
    function selectWinner1() public payable {   
        // rand.update.value(50 finney)();      
        rand.update.value(msg.value)();  //生成随机数花费0.05ETH   
        winner = rand.randomNumber() % participantsCount; 
        emit winnerIndex("winner is ", winner, participants[winner]);
    }

    //伪随机数
    function selectWinner2() public  { 
        uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce)));
        randNonce++;  
        winner = random % participantsCount; 
        emit winnerIndex("winner is ", winner, participants[winner]);
    }

}
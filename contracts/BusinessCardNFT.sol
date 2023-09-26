// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// 전송할 Business Card가 없을 때 뜰 커스텀 오류
error No_Business_Card_To_Transfer();

contract BusinessCardNFT is ERC721URIStorage, ReentrancyGuard{
    using Counters for Counters.Counter;

    // 명함에 들어갈 정보 구조
    struct BusinessCardInfo {
        string name;
        string email;
        address issuer;
    }

    // mapping : solidity에서 데이터를 저장하는 방법, 기본적으로 key-value의 형태로 저장한다고 생각하면 됨
    // _bcInfo : issuer가 발행한 BusinessCardInfo
    mapping(address => BusinessCardInfo) private _bcInfo;
    // _tokenIdsMadeByIssuer : issuer가 발행한 tokenId를 담을 동적배열
    mapping(address => uint[]) private _tokenIdsMadeByIssuer;
    // _isTokenOwnerByIssuer : tokenId가 현재 issuer에게 있는지, 있으면 true 없으면 false
    // 이중 mapping이기 때문에 [address][uint]를 찾아서 값을 넣으면 됨
    mapping(address => mapping(uint => bool)) private _isTokenOwnedByIssuer;
    // _amountOfTokenOwnedByIssuer : issuer가 가진 명함 갯수 = 발급한 양 - 다른 사람에게 전송한 양
    mapping(address => uint) private _amountOfTokenOwnedByIssuer;
    // _checkAmountOfTokenOwnedExceptIssuer : token을 가졌는지 체크
    mapping(address => uint) private _checkAmountOfTokenOwnedExceptIssuer;

    uint public MAX_BUSINESS_CARD = 1;      // 한 사람당 가질 수 있는 내 명함 개수
    uint public MINT_AMOUNTS = 10;          // 한 번 민팅할 때 민팅할 양
    uint public MINT_PRICE = 0.01 ether;    // 한 번 민팅할 때 민팅 가격

    address public immutable owner;
    Counters.Counter private _tokenIds;

    // 블록체인에서 트랜잭션이 완료되면 트랜잭션이 실행하는 동안 발생했던 행위에 관련된 정보들을 제공하는 로그 엔트리(log entry)들을 갖음
    // event : 로그를 만들기 위한 객체 (JavaScript 상에서 해당 객체를 확인할 수 있음)
    // event에 indexed 키워드를 사용하는 이유는 특정 event 값을 불러올 수 있기 때문
    // JavaScript에서 filter 기능을 사용할 경우 indexed가 적혀져 있을 경우에만 해당 기능이 정상적으로 작동함
    // BusinessCardInfoRegistered : 명함 정보 event
    event BusinessCardInfoRegistered(address indexed issuer, string name, string email);
    // BusinessCardMinted : 명함 민팅 event
    event BusinessCardMinted(uint indexed tokenId, address issuer, uint amountOfTokenOwnedByIssuer);
    // BusinessCardTransfered : 명함 전송 event
    event BusinessCardTransfered(address indexed to, address from, uint tokenId, uint amountOfTokenOwnedByIssuer);

    // modifier : 함수 전후로 실행 가능한 코드. require가 같이 쓰임
    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isBusinessCardInfoRegistered {
        BusinessCardInfo memory myBusinessCardInfo = _bcInfo[msg.sender];
        require(keccak256(abi.encodePacked(myBusinessCardInfo.name)) != keccak256(abi.encodePacked("")), "Register your business card first");
        _;
    }

    // ERC721 Contract : constructor를 가면 _name, _symbol의 형태로 작성되어 있음
    constructor() ERC721("Eunbeen", "EB") {
        owner = msg.sender; // contract 소유자 주소
    }

    // function
    /**
     * @dev 명함 정보 등록하는 함수, 오너만 가능
     * @param _name  명함 정보에 들어갈 이름
     * @param _email 명함 정보에 들어갈 이메일
     */
    function resgisterBusinessCardInfo(string memory _name, string memory _email) public onlyOwner{
        BusinessCardInfo memory businessCardInfo = BusinessCardInfo({
            name: _name,
            email: _email,
            issuer: msg.sender
        });
        _bcInfo[msg.sender] = businessCardInfo;
        // emit : event를 발생시킬 경우 사용하는 키워드
        emit BusinessCardInfoRegistered(msg.sender, _name, _email);
    }

    /**
     * @dev BusinessCard를 민팅하는 함수, MINT_AMOUNTS개씩 민팅 가능(현재는 10개), 오너만 가능
     * @param tokenURI 명함 IMAGE URI
     */
    function mintBusinessCard(string memory tokenURI) public payable onlyOwner isBusinessCardInfoRegistered nonReentrant{
        require(msg.value == MINT_PRICE, "Check Mint Price");

        // for문보다 좋은 게 머가 있을까..
        for (uint i = 0; i < MINT_AMOUNTS; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            // ERC721 Contract : _mint 함수에는 address _to, uint256 tokenId을 매개변수로 받고 있음
            _mint(msg.sender, newTokenId);
            // ERC721URIStorage Contract : _setTokenURI에는 uint256 tokenId, string tokenURI를 매개변수로 받고 있음
            _setTokenURI(newTokenId, tokenURI);

            // mapping 업데이트
            uint[] storage tokenIdsMadeByIssuer = _tokenIdsMadeByIssuer[msg.sender];
            tokenIdsMadeByIssuer.push(newTokenId);
            _isTokenOwnedByIssuer[msg.sender][newTokenId] = true;

            emit BusinessCardMinted(newTokenId, msg.sender, _amountOfTokenOwnedByIssuer[msg.sender]);
        }

        _amountOfTokenOwnedByIssuer[msg.sender] = _amountOfTokenOwnedByIssuer[msg.sender] + 10;
    }

    /**
     * @dev BusinessCard를 전송하는 함수
     * @param _to 명함 전송할 주소
     */
    function transferBusinessCard(address _to) public isBusinessCardInfoRegistered {
        require(_amountOfTokenOwnedByIssuer[msg.sender] != 0, "Mint your business card First");
        require(_checkAmountOfTokenOwnedExceptIssuer[_to] < MAX_BUSINESS_CARD, "Already have business card");

        uint tokenIdToTransfer;
        uint[] memory tokenIdsMadeByIssuer = _tokenIdsMadeByIssuer[msg.sender];
        
        // issuer가 만든 tokenId 배열에 담아서 반복문을 사용하여 issuer가 소유한 tokenId를 찾음
        // true인 tokenId가 있다면 반복문 종료
        for (uint i = 0; i < tokenIdsMadeByIssuer.length; i++) {
            uint tokenId = tokenIdsMadeByIssuer[i];
            if (_isTokenOwnedByIssuer[msg.sender][tokenId] == true) {
                tokenIdToTransfer = tokenId;
                break;
            }
            // 만약 i가 tokenIdsMadeByIssuer.length - 1이고 tokenId를 소유하지 않았다면 에러 발생
            if ((i == tokenIdsMadeByIssuer.length - 1) && (_isTokenOwnedByIssuer[msg.sender][tokenId] == false)){
                revert No_Business_Card_To_Transfer();
            }
        }
        // ERC721 Contract : safeTransferFrom에는 address from, address to, uint256 tokenId를 매개변수로 받고 있음
        safeTransferFrom(msg.sender, _to, tokenIdToTransfer);

        // mapping 업데이트
        _isTokenOwnedByIssuer[msg.sender][tokenIdToTransfer]= false;
        _amountOfTokenOwnedByIssuer[msg.sender]--;
        _checkAmountOfTokenOwnedExceptIssuer[_to]++;

        emit BusinessCardTransfered(_to, msg.sender, tokenIdToTransfer, _amountOfTokenOwnedByIssuer[msg.sender]);
    }

    /**
     * @dev 명함 정보 얻는 view 함수
     * @param issuer 명함 민팅한 주소
     */
    function getBusinessCardInfo(address issuer) external view returns(BusinessCardInfo memory){
        return _bcInfo[issuer];
    }

    /**
     * @dev 가지고 있는 명함 갯수 확인하는 view 함수
     * @param issuer 명함 민팅한 주소
     */
    function getAmountOfTokenOwnedByIssuer(address issuer) external view returns(uint){
        return _amountOfTokenOwnedByIssuer[issuer];
    }
}
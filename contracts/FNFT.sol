pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./ERC921.sol";

/*
*	Federated Non-Fungible Token Implementation.
*	FNFT contract has a limited number of fungible "writs", which can be
*	defined in a metadata document via the writ field. Example writ: m^2.
*	An FNFT representing a particular geospace of 10000m^2 would begin with
* 	10000 writs. From then it is possible to delegate new FNFTs with a new
*	owner, giving them control over writs (this is a recursive process).
*	FNFTs can also be revoked by the parent- which reassigns ownership to
*	FNFT that delegated it in the first place.
*/

contract FNFT is ERC721, ERC921 {
	
	uint public totalSupply;
	string public writ;

	struct fnft {
		string metadata;
		uint depth;
		uint index;
		uint writs;
		address owner;
	}

	struct delegates {
		uint total;
		mapping(uint => bool) fnfts;
	}

	event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    event Delegate(
    	uint _tokenId,
    	uint _delegate,
    	address indexed _owner
    );

    event Revoke(
    	uint _tokenId,
    	uint _delegate
    );

	mapping(uint => fnft) internal tokenIndex;
	mapping(address => uint[]) internal ownerIndex;
	mapping(uint => address) internal approvalIndex;
	mapping(uint => delegates) internal delegateIndex;

	modifier onlyExtantToken(uint _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

	function FNFT(string _writ, string _metadata, uint _balance, address _owner) 
		public 
	{
		
		writ = _writ;

		tokenIndex[0].metadata = _metadata;
		tokenIndex[0].depth = 0;
		tokenIndex[0].index = 0;
		tokenIndex[0].writs = _balance;
		tokenIndex[0].owner = _owner;

		ownerIndex[_owner].push(0);
	}

	function getMetadata(uint _tokenId)
		public
		view
		returns (string _metadata)
	{
		return tokenIndex[_tokenId].metadata;
	}

	function tokenBalance(uint _tokenId)
		public
		view
		returns (uint _writs)
	{
		return tokenIndex[_tokenId].writs;
	}

	function totalSupply() 
		public 
		view 
		returns (uint _totalSupply) 
	{
		return totalSupply;
	}

    function balanceOf(address _owner) 
    	public 
    	view 
    	returns (uint _balance) 
    {
    	return ownerIndex[_owner].length;
    }

    function ownerOf(uint _tokenId) 
    	public 
    	view 
    	returns (address _owner) 
    {
    	return tokenIndex[_tokenId].owner;
    }

    function approve(address _to, uint _tokenId)
        public
        onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (approvalIndex[_tokenId] != address(0) ||
                _to != address(0)) {
            approvalIndex[_tokenId] = _to;
            emit Approval(msg.sender, _to, _tokenId);
        }
    }

    function getApproved(uint _tokenId) 
    	public 
    	view 
    	returns (address _approved) 
    {
    	return approvalIndex[_tokenId];
    }

    function transferFrom(address _from, address _to, uint _tokenId) 
    	public
    	onlyExtantToken(_tokenId)
    {
    	require(getApproved(_tokenId) == msg.sender);
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        clearApprovalAndTransfer(_from, _to, _tokenId);

        emit Approval(_from, 0, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint _tokenId) 
    	public
    	onlyExtantToken(_tokenId)
    {
    	require(ownerOf(_tokenId) == msg.sender);
        require(_to != address(0));

        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
        emit Approval(msg.sender, 0, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function implementsERC721() 
    	public 
    	view 
    	returns (bool _implementsERC721) 
    {
    	return true;
    }

    function isDelegate(uint _tokenId, uint _delegate) 
    	public 
    	view 
    	returns(bool _isDelegate)
    {
    	return delegateIndex[_tokenId].fnfts[_delegate];
    }

	function totalDelegates(uint _tokenId) 
		public 
		view 
		returns(uint _totalDelegates) 
	{
		return delegateIndex[_tokenId].total;
	}


	function getDepth(uint _tokenId) 
		public 
		view 
		returns(uint _depth)
	{
		return tokenIndex[_tokenId].depth;
	}

	function delegate(uint _tokenId, uint _writs, address _newowner, string _metadata) 
		public
		onlyExtantToken(_tokenId)
	{
		require(ownerOf(_tokenId) == msg.sender);
		require(tokenBalance(_tokenId) >= _writs);
		require(_newowner != address(0));
		require(bytes(_metadata).length > 0);

		uint depth = tokenIndex[_tokenId].depth++;
		uint newTokenId = totalSupply;

		tokenIndex[_tokenId].writs -= _writs;
		tokenIndex[newTokenId].writs += _writs;
		tokenIndex[newTokenId].metadata = _metadata;
		tokenIndex[newTokenId].depth = depth;

		addToDelegateIndex(_tokenId, newTokenId);
		addToOwnerIndex(_newowner, newTokenId);

		totalSupply++;

		emit Delegate(_tokenId, newTokenId, _newowner);
	}
	

	function revoke(uint _tokenId, uint _delegate) 
		public
		onlyExtantToken(_tokenId)
	{
		require(ownerOf(_tokenId) == msg.sender);
		require(isDelegate(_tokenId, _delegate));

		address from = tokenIndex[_delegate].owner;

		clearApprovalAndTransfer(from, msg.sender, _delegate);

		emit Approval(from, 0, _tokenId);
        emit Transfer(from, msg.sender, _tokenId);
		emit Revoke(_tokenId, _delegate);
	}
	

	function implementsERC921() 
		public 
		view 
		returns(bool _implementsERC921) 
	{
		return true;
	}


	/* Internal methods */

	function clearApprovalAndTransfer(address _from, address _to, uint _tokenId)
        internal
    {
        approvalIndex[_tokenId] = address(0);
      
        removeFromOwnerIndex(_from, _tokenId);
        addToOwnerIndex(_to, _tokenId);

        tokenIndex[_tokenId].owner = _to;
    }

    function addToOwnerIndex(address _owner, uint _tokenId)
    	internal
    {
    	ownerIndex[_owner].push(_tokenId);
    	tokenIndex[_tokenId].index = ownerIndex[_owner].length;
    }

    function removeFromOwnerIndex(address _owner, uint _tokenId)
        internal
    {
        uint length = ownerIndex[_owner].length;
        uint index = tokenIndex[_tokenId].index;
        uint swapToken = ownerIndex[_owner][length - 1];

        ownerIndex[_owner][index] = swapToken;
        tokenIndex[swapToken].index = index;

        delete ownerIndex[_owner][length - 1];
        ownerIndex[_owner].length--;
    }

    function addToDelegateIndex(uint _tokenId, uint _delegate)
    	internal
    {
    	delegateIndex[_tokenId].fnfts[_delegate] = true;
    	delegateIndex[_tokenId].total++;
    }


}
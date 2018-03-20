pragma solidity ^0.4.17;
import "./StandardOrdinate.sol";
import "./IDNFT.sol";

contract O_Option is StandardOrdinate {

	IDNFT dnft;
	// the time when the option is available from
	uint256 public timestart;
	// the term for which the option lasts
	uint256 public timeout;
	// the price at which the option can be exercised
	uint256 public strikePrice;
	// the address of the buyer to the option
	address public buyer;
	// the address of the controlling seller
	address public seller;
	// the address ownership is restored if option fails to be exercised.
	address public default;
	// the tokenId of the DNFT held by the contract
	uint256 public tokenId;

	event O_OptionStart(uint256 tokenId, 
		uint256 strikePrice, 
		uint256 timeout, 
		address indexed buyer);

	event O_OptionExercised(uint256 tokenId, 
		uint256 strikePrice, 
		uint256 timeout, 
		address indexed buyer);
	
	event O_OptionExpired(uint256 tokenId);

	function O_Option(address _dnft)
		public
	{
		dnft = IDNFT(_dnft);
		seller = msg.sender;
	}

	function initiate(address _default, uint256 _tokenId, uint256 _timeout, uint256 _strikePrice, address buyer)
		public
	{
		require(msg.sender == seller);
		require(tokenId == 0);

		require(dnft.transferFrom(_tokenId));
		require(dnft.ownerOf(_tokenId) == address(this));

		strikePrice = _strikePrice;
		timeout = _timeout;
		buyer = _buyer;
	}


}
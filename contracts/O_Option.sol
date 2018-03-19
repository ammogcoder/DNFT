pragma solidity ^0.4.17;
import "./StandardOrdinate.sol";
import "./IDNFT.sol";

contract O_Option is StandardOrdinate {

	// the 
	IDNFT dnft;
	// the term is the time the option lasts
	uint256 public timeout;

	// the price at which the option can be exercised
	uint256 public strikePrice;

	// the address of the buyer to the option
	address public buyer;

	function O_Option(address _dnft, 
		uint256 _timeout, 
		uint256 _strikePrice, 
		address _buyer) {
		
	}
}
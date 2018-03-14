pragma solidity ^0.4.18;

import "./FNFT.sol";

contract Zone {

	address owner;

	mapping(address => bool) zones;

	event ZoneCreation(
		address indexed zone, 
		address indexed owner, 
		string writ, 
		uint balance
	);

	function Zone() 
	{
		owner = msg.sender;
	}
	
	function makeNewFNFT(string _writ, string _metadata, uint _balance, address _owner)
		public
	{
		require(owner == msg.sender);
		address newzone = new FNFT(_writ, _metadata, _balance, _owner);

		require(newzone != address(0));
		zones[newzone] = true;

		emit ZoneCreation(newzone, _owner, _writ, _balance);
	}
}
pragma solidity ^0.4.17;


contract ERC921 {
	function isDelegate(uint _tokenId, uint _delegate) public view returns(bool _isDelegate);
	function totalDelegates(address _tokenId) public view returns(uint _totalDelegates);
	function getDepth(uint _tokenId) public view returns(uint _depth);
	function tokenBalance(uint _tokenId) public view returns (uint _writs);
	function delegate(uint _tokenId, uint _delegate) public;
	function revoke(uint _tokenId, uint _delegate) public;
	function implementsERC921() public view returns(bool _implementsERC921);

	event Delegate(uint _tokenId, uint _delegate, address indexed _owner);
	event Revoke(uint _tokenId, uint _delegate);
}
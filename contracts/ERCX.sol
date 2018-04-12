pragma solidity ^0.4.17;
/// @title DNFT Delegated Non-Fungible Token Standard

interface DNFT {

	/// @dev checks if _from is a delegate of _tokenId.
	function origin(uint256 _from, uint256 _tokenId) public view returns (bool);
	
	/// @dev gets the abstraction depth of _tokenId. 
	function getHeight(uint256 _tokenId) public view returns (uint256);
	
	/// @dev returns the balance of writs.
	function available(uint256 _tokenId) public view returns (uint256);
	
	/// @dev allows tokenholder to delegate new DNFT.
	function delegate(uint256 _tokenId, uint256 _delegate) public;
	
	/// @dev allows owner to revoke a delegate NFT.
	function revoke(uint256 _tokenId, uint256 _delegate) public;

	/// @dev emitted whenever a new DNFT subdomain is delegated.
	event Delegate(uint256 _from, uint256 _tokenId, address indexed _owner);
	
	/// @dev emitted whenever an DNFT subdomain is revoked.
	event Revoke(uint256 _tokenId, uint256 _delegate);
}

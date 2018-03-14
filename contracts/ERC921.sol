pragma solidity ^0.4.17;

import "./ERC721.sol";

/// @title ERC-921 Federated Non-Fungible Token Standard (Zones)
// For zone property registries. Base FNFT established by jurisdiction.
// Owners of a token are allowed to federate new tokens at a higher level of abstraction.

interface ERC921 is ERC721 {

	/// @dev emitted whenever a new FNFT subdomain is delegated.
	event Delegate(uint _tokenId, uint _delegate, address indexed _owner);

	/// @dev emitted whenever an FNFT subdomain is revoked
	event Revoke(uint _tokenId, uint _delegate);

	/// @dev checks whether delegate tokenId is a subdomain of _tokenId
	function delegatedFrom(uint _delegate, uint _tokenId) external view returns(bool _delegatedFrom);

	/// @dev gets the abstraction depth of _tokenId. Primary domain is 1, Secondary 2, etc.
	function getHeight(uint _tokenId) external view returns(uint _height);

	/// @dev returns the balance of writs (fungible delegated physical-space units)
	function available(uint _tokenId) external view returns (uint _writs);

	/// @dev allows tokenholder to delegate (mint) a new FNFT at a higher level
	function delegate(uint _tokenId, uint _delegate) external payable;

	/// @dev allows owner to revoke a delegate NFT under its jurisdiction.
	function revoke(uint _tokenId, uint _delegate) external;

	/// @dev checks if implements standard.
	function implementsERC921() external view returns(bool _implementsERC921);

}
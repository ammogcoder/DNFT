pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./ERC921.sol";
import "./SafeMath.sol";

contract FNFT is ERC721, ERC921 {
  using SafeMath for uint256;

  // total amount of fnft tokens in zone.
  uint private totalTokens;

  // maps token id to owning address
  mapping(uint256 => address) private owner;

  // maps token id to string metadata uri
  mapping(uint256 => string) private metadata;

  // maps token id to fungible land units (writs).
  mapping(uint256 => uint256) private writs;

  // maps child delegate token to parent ID
  mapping(uint256 => uint256) private sub;

  // maps token id to depth index
  mapping(uint256 => uint256) private height;

  // maps token id to approved address
  mapping(uint256 => address) private approvals;

  // maps token id to list of owned tokens
  mapping(address => uint256[]) private inventory;

  // maps token id to the index of owned tokens
  mapping(uint256 => uint256) private index;


  event Metadata(
    uint256 tokenId, 
    string metadata
  );

  /**
    * @dev Guarantees msg.sender is owner of the given token
    * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _tokenId) 
    {
      require(ownerOf(_tokenId) == msg.sender);
      _;
    }

    /**
    * @dev extant = in existence. Checks to make sure token exists
    * @param _tokenId ID of the token being checked
    */
    modifier onlyExtantToken(uint256 _tokenId)
    {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    /**
    * @dev returns the string metadata associated with a particular token
    * @param _tokenId the ID of the NFT
    * @return _uri the metadata document location
    */

    function getMetadata(uint _tokenId)
      public
      view
      returns(string _uri)
    {
      return metadata[_tokenId];
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() 
      public 
      view 
      returns (uint256) 
    {
      return totalTokens;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) 
      public 
      view 
      returns (uint256) 
    {
      return inventory[_owner].length;
    }

    /**
    * @dev Gets the list of tokens owned by a given address
    * @param _owner address to query the tokens of
    * @return uint256[] representing the list of tokens owned by the passed address
    */
    function inventoryOf(address _owner) 
      public 
      view 
      returns (uint256[]) 
    {
      return inventory[_owner];
    }

    /**
    * @dev Gets the owner of the specified token ID
    * @param _tokenId uint256 ID of the token to query the owner of
    * @return owner address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 _tokenId) 
      public 
      view 
      returns (address _ownerOf) 
    {
      address _owner = owner[_tokenId];
      require(_owner != address(0));
      return _owner;
    }

    /**
    * @dev Gets the approved address to take ownership of a given token ID
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved to take ownership of the given token ID
    */
    function approvedFor(uint256 _tokenId) 
      public 
      view 
      returns (address) 
    {
      return approvals[_tokenId];
    }

    /**
    * @dev Confirms whether or not token is a subdomain of given token ID
    * @param _delegate uint256 ID of the queried delegate token
    * @param _tokenId uint256 ID of the origin parent token
    * @return bool true if queried token is delegate of tokenId, false if not
    */
    function delegatedFrom(uint256 _delegate, uint256 _tokenId) 
      public 
      view
      returns(bool _delegatedFrom)
    {
      return sub[_delegate] == _tokenId;
    }

    /**
    * @dev checks the number of available writs for a particular token.
    * @param _tokenId the uint256 token to check
    * @return _writs the number of available physical units left to use or delegate
    */

    function available(uint _tokenId) 
      public 
      view 
      returns (uint256 _writs)
    {
      return writs[_tokenId];
    }

    /** 
    * @dev gets the abstraction height of _tokenId. Primary domain is 1, Secondary 2, etc.
  * @param _tokenId the uint256 ID to check height.
  * @return _height the domain of the token.
  */
  function getHeight(uint _tokenId)
      public
    view 
    returns(uint _height) 
  {
    return height[_tokenId];
  }


    /**
    * @dev Transfers the ownership of a given token ID to another address
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function transfer(address _to, uint256 _tokenId) 
      public 
      onlyOwnerOf(_tokenId)
      onlyExtantToken(_tokenId)
    {
      clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

    /**
    * @dev Approves another address to claim for the ownership of the given token ID
    * @param _to address to be approved for the given token ID
    * @param _tokenId uint256 ID of the token to be approved
    */
    function approve(address _to, uint256 _tokenId) 
      public 
      onlyOwnerOf(_tokenId)
      onlyExtantToken(_tokenId) 
    {
      address _owner = ownerOf(_tokenId);
      require(_to != _owner);
      if (approvedFor(_tokenId) != 0 || _to != 0) {
          approvals[_tokenId] = _to;
          emit Approval(_owner, _to, _tokenId);
      }
    }

    /**
    * @dev Claims the ownership of a given token ID
    * @param _tokenId uint256 ID of the token being claimed by the msg.sender
    */
    function transferFrom(uint256 _tokenId) 
      public
      onlyExtantToken(_tokenId)
    {
      require(isApprovedFor(msg.sender, _tokenId));
      clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function setMetadata(uint256 _tokenId, string _metadata)
      public
      onlyExtantToken(_tokenId)
    {
        uint _subtoken = sub[_tokenId];
        address _subowner = owner[_subtoken];
      require(_subowner == msg.sender);
      metadata[_tokenId] = _metadata;
      emit Metadata(_tokenId, _metadata);
    }


    /// @dev allows tokenholder to delegate (mint) a new FNFT at a higher level
  function delegate(uint256 _tokenId, uint256 _writs, address _newowner) 
    public
    onlyOwnerOf(_tokenId)
    onlyExtantToken(_tokenId)
  {
    require(available(_tokenId) >= _writs);
    require(_newowner != address(0));

    uint256 newHeight = height[_tokenId].add(1);
    uint256 newTokenId = totalTokens;

    owner[newTokenId] = _newowner;
    sub[newTokenId] = _tokenId;
    height[newTokenId] = newHeight;

    writs[_tokenId].sub(_writs);
    writs[newTokenId] = _writs;

    addToInventory(_newowner, newTokenId);

    totalTokens.add(1);

    emit Delegate(_tokenId, newTokenId, _newowner);
  }

  /// @dev allows owner to revoke a delegate NFT under its jurisdiction.
  function revoke(uint256 _tokenId, uint256 _delegate)
    public
    onlyOwnerOf(_tokenId)
    onlyExtantToken(_tokenId)
  {
    require(sub[_delegate] == _tokenId);

    address from = owner[_delegate];

    clearApprovalAndTransfer(from, msg.sender, _delegate);

    emit Transfer(from, msg.sender, _delegate);
    emit Revoke(_tokenId, _delegate);
  }

    /**
    * @dev Tells whether the msg.sender is approved for the given token ID or not
    * This function is not private so it can be extended in further implementations like the operatable ERC721
    * @param _owner address of the owner to query the approval of
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return bool whether the msg.sender is approved for the given token ID or not
    */
    function isApprovedFor(address _owner, uint256 _tokenId) 
      internal 
      view 
      returns (bool) 
    {
      return approvedFor(_tokenId) == _owner;
    }


    /**
    * @dev Internal function to clear current approval and transfer the ownership of a given token ID
    * @param _from address which you want to send tokens from
    * @param _to address which you want to transfer the token to
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) 
      internal 
    {
      require(_to != address(0));
      require(_to != ownerOf(_tokenId));
      require(ownerOf(_tokenId) == _from);

      clearApproval(_from, _tokenId);
      removeFromInventory(_from, _tokenId);
      addToInventory(_to, _tokenId);
      emit Transfer(_from, _to, _tokenId);
  }

    /**
    * @dev Internal function to clear current approval of a given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApproval(address _owner, uint256 _tokenId) 
      private 
    {
      require(ownerOf(_tokenId) == _owner);
      approvals[_tokenId] = 0;
      emit Approval(_owner, 0, _tokenId);
    }

  /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addToInventory(address _to, uint256 _tokenId) 
      private 
    {
      require(owner[_tokenId] == address(0));
      owner[_tokenId] = _to;
      uint256 length = balanceOf(_to);
      inventory[_to].push(_tokenId);
      index[_tokenId] = length;
      totalTokens = totalTokens.add(1);
    }

    /**
    * @dev Internal function to remove a token ID from the index of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeFromInventory(address _from, uint256 _tokenId) 
      private 
    {
      require(ownerOf(_tokenId) == _from);

      uint256 tokenIndex = index[_tokenId];
      uint256 lastTokenIndex = balanceOf(_from).sub(1);
      uint256 lastToken = inventory[_from][lastTokenIndex];

      owner[_tokenId] = 0;
      inventory[_from][tokenIndex] = lastToken;
      inventory[_from][lastTokenIndex] = 0;
      
      // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
      // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
      // the lastToken to the first position, and then dropping the element placed in the last position of the list

      inventory[_from].length--;
      index[_tokenId] = 0;
      index[lastToken] = tokenIndex;
      totalTokens = totalTokens.sub(1);
    }
}






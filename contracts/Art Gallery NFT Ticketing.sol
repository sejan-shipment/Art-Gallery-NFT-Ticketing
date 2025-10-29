// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Art Gallery NFT Ticketing
 * @dev A smart contract for minting, managing, and validating NFT-based art gallery tickets
 */
contract Project {
    
    // Struct to represent a ticket
    struct Ticket {
        uint256 tokenId;
        address owner;
        string galleryName;
        uint256 visitDate;
        bool isUsed;
    }
    
    // State variables
    address public galleryOwner;
    uint256 public ticketCounter;
    uint256 public ticketPrice;
    
    // Mappings
    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256[]) public userTickets;
    
    // Events
    event TicketMinted(uint256 indexed tokenId, address indexed buyer, string galleryName, uint256 visitDate);
    event TicketValidated(uint256 indexed tokenId, address indexed owner);
    event TicketTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    
    // Modifiers
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can perform this action");
        _;
    }
    
    modifier ticketExists(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= ticketCounter, "Ticket does not exist");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     * @param _ticketPrice Price of each ticket in wei
     */
    constructor(uint256 _ticketPrice) {
        galleryOwner = msg.sender;
        ticketPrice = _ticketPrice;
        ticketCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Mint a new NFT ticket
     * @param _galleryName Name of the art gallery or exhibition
     * @param _visitDate Timestamp for the scheduled visit date
     */
    function mintTicket(string memory _galleryName, uint256 _visitDate) public payable {
        require(msg.value >= ticketPrice, "Insufficient payment for ticket");
        require(_visitDate > block.timestamp, "Visit date must be in the future");
        require(bytes(_galleryName).length > 0, "Gallery name cannot be empty");
        
        ticketCounter++;
        
        tickets[ticketCounter] = Ticket({
            tokenId: ticketCounter,
            owner: msg.sender,
            galleryName: _galleryName,
            visitDate: _visitDate,
            isUsed: false
        });
        
        userTickets[msg.sender].push(ticketCounter);
        
        emit TicketMinted(ticketCounter, msg.sender, _galleryName, _visitDate);
    }
    
    /**
     * @dev Core Function 2: Validate and use a ticket at the gallery entrance
     * @param _tokenId The ID of the ticket to validate
     */
    function validateTicket(uint256 _tokenId) public onlyGalleryOwner ticketExists(_tokenId) {
        Ticket storage ticket = tickets[_tokenId];
        
        require(!ticket.isUsed, "Ticket has already been used");
        require(block.timestamp >= ticket.visitDate - 1 days, "Too early to use this ticket");
        require(block.timestamp <= ticket.visitDate + 1 days, "Ticket has expired");
        
        ticket.isUsed = true;
        
        emit TicketValidated(_tokenId, ticket.owner);
    }
    
    /**
     * @dev Core Function 3: Transfer ticket to another address
     * @param _tokenId The ID of the ticket to transfer
     * @param _to Address of the new owner
     */
    function transferTicket(uint256 _tokenId, address _to) public ticketExists(_tokenId) {
        Ticket storage ticket = tickets[_tokenId];
        
        require(ticket.owner == msg.sender, "You are not the owner of this ticket");
        require(!ticket.isUsed, "Cannot transfer a used ticket");
        require(_to != address(0), "Invalid recipient address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        
        address previousOwner = ticket.owner;
        ticket.owner = _to;
        
        // Update user tickets mapping
        userTickets[_to].push(_tokenId);
        
        emit TicketTransferred(_tokenId, previousOwner, _to);
    }
    
    /**
     * @dev Get all tickets owned by a user
     * @param _user Address of the user
     * @return Array of ticket IDs
     */
    function getUserTickets(address _user) public view returns (uint256[] memory) {
        return userTickets[_user];
    }
    
    /**
     * @dev Get ticket details
     * @param _tokenId The ID of the ticket
     * @return Ticket struct details
     */
    function getTicketDetails(uint256 _tokenId) public view ticketExists(_tokenId) returns (Ticket memory) {
        return tickets[_tokenId];
    }
    
    /**
     * @dev Update ticket price (only gallery owner)
     * @param _newPrice New ticket price in wei
     */
    function updateTicketPrice(uint256 _newPrice) public onlyGalleryOwner {
        require(_newPrice > 0, "Price must be greater than zero");
        ticketPrice = _newPrice;
    }
    
    /**
     * @dev Withdraw funds from the contract (only gallery owner)
     */
    function withdrawFunds() public onlyGalleryOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(galleryOwner).transfer(balance);
    }
    
    /**
     * @dev Get contract balance
     * @return Current balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

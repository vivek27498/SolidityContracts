//SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

contract PharmaSupplyChain{
    address private owner;

    struct Manufacturer{
        uint256 id; //shipmentid
        string senderName;
        uint256 senderId; //sender id
        string custName;
        string custBank;
        string typeOfMaterial;
        uint256 quantity;
        uint256 netWeight;
        uint256 insuranceId;
    }

    struct ShipmentAgent{
        uint256 id;
        uint256 agentId;
        string agentName;
        string business;
        uint256 mobileNumber;
        uint256 cargoId;
    }

    struct CargoServiceProvider{
        uint256 id;
        bool acknowledgement;
    }

    struct Customer{
        uint256 id;
        bool acknowledgement;
    }

    struct Transaction{
        uint256 id;
        mapping (uint256 => Manufacturer) manufacturerDetails;
        uint256[] manufacturerDetailsList;
        mapping (uint256 => ShipmentAgent) shipmentAgentDetails;
        uint256[] shipmentAgentDetailsList;
        mapping (uint256 => CargoServiceProvider) cargoServiceProviderDetails;
        uint256[] cargoServiceProviderDetailsList;
        mapping (uint256 => Customer) addCustomerAckDetails;
        uint256[] customerAckDetailsList;
    }

    mapping (uint256 => Manufacturer) public manfDetails;
    mapping (uint256 => ShipmentAgent) public shipmentAgentDetails;
    mapping (uint256 => CargoServiceProvider) public cargoServiceProviderDetails;
    mapping (uint256 => Customer) public customerDetails;
    mapping (uint256 => Transaction) public transactionDetails;

    uint256[] transactionStructList;
    uint256[] transactionIdList;

    constructor(){
        owner = msg.sender;
    }

    function addManufacturerDetails(uint256 _id, string memory _senderName, uint256 _senderId,
        string memory _custName, string memory _custBank, string memory _typeOfMaterial, 
        uint256 _quantity, uint256 _netWeight, uint256 _insuranceId) public{

        Manufacturer memory currentTxn;
        currentTxn.id = _id;
        currentTxn.senderName = _senderName;
        currentTxn.senderId = _senderId;
        currentTxn.custName = _custName;
        currentTxn.custBank = _custBank;
        currentTxn.typeOfMaterial = _typeOfMaterial;
        currentTxn.quantity = _quantity;
        currentTxn.netWeight = _netWeight;
        currentTxn.insuranceId = _insuranceId;

        manfDetails[_id] = currentTxn;
        transactionIdList.push(_id);

    }

    function addAgentDetails(uint256 _id, uint256 _agentId,
        string memory _agentName, string memory _business, uint256 _mobileNumber,
        uint256 _cargoId) public{
        
        ShipmentAgent memory currentAgent;
        currentAgent.id = _id;
        currentAgent.agentId = _agentId;
        currentAgent.agentName = _agentName;
        currentAgent.business = _business;
        currentAgent.mobileNumber = _mobileNumber;
        currentAgent.cargoId = _cargoId;
        
        shipmentAgentDetails[_id] = currentAgent;

    }

    function addCargoAckDetails(uint256 _id, bool _acknowledgement) public{

        CargoServiceProvider memory cargoProvider;
        cargoProvider.id = _id;
        cargoProvider.acknowledgement = _acknowledgement;

        cargoServiceProviderDetails[_id] = cargoProvider;
    }

    function addCustomerAckDetails(uint256 _id, bool _acknowledgement) public{

        Customer memory customer;
        customer.id = _id;
        customer.acknowledgement = _acknowledgement;

        customerDetails[_id] = customer;
    }

    function addManufacturerDetails2(uint256 _id, string memory _senderName, uint256 _senderId,
        string memory _custName, string memory _custBank, string memory _typeOfMaterial, 
        uint256 _quantity, uint256 _netWeight, uint256 _insuranceId) public{

        transactionDetails[_id].id = _id;
        transactionDetails[_id].manufacturerDetails[_id].senderName = _senderName;
        transactionDetails[_id].manufacturerDetails[_id].senderId = _senderId;
        transactionDetails[_id].manufacturerDetails[_id].custName = _custName;
        transactionDetails[_id].manufacturerDetails[_id].custBank = _custBank;
        transactionDetails[_id].manufacturerDetails[_id].typeOfMaterial = _typeOfMaterial;
        transactionDetails[_id].manufacturerDetails[_id].quantity = _quantity;
        transactionDetails[_id].manufacturerDetails[_id].netWeight = _netWeight;
        transactionDetails[_id].manufacturerDetails[_id].insuranceId = _insuranceId;
        transactionDetails[_id].manufacturerDetails[_id].senderId = _senderId;

        transactionIdList.push(_id);
        transactionDetails[_id].manufacturerDetailsList.push(_id);
    
    }

    function addShipmentDetails(uint256 _id, uint256 _agentId,
        string memory _agentName, string memory _business, uint256 _mobileNumber) public{

        require(transactionDetails[_id].id != 0, "Invalid id!");
        require(transactionDetails[_id].id == _id, "Invaild ID!");
        
        transactionDetails[_id].shipmentAgentDetails[_id].agentId = _agentId;
        transactionDetails[_id].shipmentAgentDetails[_id].agentName = _agentName;
        transactionDetails[_id].shipmentAgentDetails[_id].business = _business;
        transactionDetails[_id].shipmentAgentDetails[_id].mobileNumber = _mobileNumber;

        transactionDetails[_id].shipmentAgentDetailsList.push(_id);
    }

    function addCargoAckDetails2(uint256 _id, bool _acknowledgement) public{
        require(transactionDetails[_id].id != 0 ,"Invalid ID!");
        require(transactionDetails[_id].id == _id, "Invalid ID!");

        transactionDetails[_id].cargoServiceProviderDetails[_id].acknowledgement = _acknowledgement;
        transactionDetails[_id].id = _id;
        transactionDetails[_id].cargoServiceProviderDetailsList.push(_id);
    }

    function addCustomerAckDetails2(uint256 _id, bool _acknowledgement) public{
        require(transactionDetails[_id].id != 0 ,"Invalid ID!");
        require(transactionDetails[_id].id == _id, "Invalid ID!");

        transactionDetails[_id].addCustomerAckDetails[_id].acknowledgement = _acknowledgement;
        transactionDetails[_id].id = _id;
        transactionDetails[_id].customerAckDetailsList.push(_id);
        
    }
    
    
    function getTransaction(uint256 _id) public view returns(uint256, Manufacturer memory, ShipmentAgent memory, CargoServiceProvider memory, Customer memory){
        return (transactionDetails[_id].id,
        transactionDetails[_id].manufacturerDetails[_id],
        transactionDetails[_id].shipmentAgentDetails[_id],
        transactionDetails[_id].cargoServiceProviderDetails[_id],
        transactionDetails[_id].addCustomerAckDetails[_id]);
        
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

contract MyToken is IERC20 {
    // Métadonnées basiques du token
    string public name;
    string public symbol;
    uint8 public decimals;

    // Total supply stocké en privé
    uint256 private _totalSupply;

    // Soldes et allowances (nommage imposé)
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Propriétaire du contrat (pour mint)
    address public owner;

    // Événements ERC-20 classiques
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "MyToken: caller is not the owner");
        _;
    }

    constructor() {
        name = "MyToken";
        symbol = "MTK";
        decimals = 18;

        owner = msg.sender;

        // 1 000 000 * 10^decimals
        uint256 initialSupply = 1_000_000 * (10 ** uint256(decimals));
        _totalSupply = initialSupply;

        // Tous les tokens pour le deployer
        balanceOf[msg.sender] = initialSupply;

        // Event de mint initial (standard ERC-20)
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    // ==== Fonctions de l'interface IERC20 ====

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // NB:
    // - balanceOf(address) est automatiquement générée par le mapping public balanceOf
    // - allowance(address,address) est automatiquement générée par le mapping public allowance

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        require(spender != address(0), "MyToken: approve to the zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        override
        returns (bool)
    {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "MyToken: transfer amount exceeds allowance"
        );

        _transfer(sender, recipient, amount);

        // Mise à jour de l'allowance
        allowance[sender][msg.sender] = currentAllowance - amount;
        emit Approval(sender, msg.sender, allowance[sender][msg.sender]);

        return true;
    }

    // ==== Bonus : mint & burn ====

    /// @notice Mint réservé au propriétaire
    /// @param amount Montant à créer (en unités "entières", incluant les décimales)
    function mint(uint256 amount) external onlyOwner {
        require(owner != address(0), "MyToken: owner is the zero address");

        _totalSupply += amount;
        balanceOf[owner] += amount;

        emit Transfer(address(0), owner, amount);
    }

    /// @notice Permet à chacun de bruler ses propres tokens
    /// @param amount Montant à détruire
    function burn(uint256 amount) external {
        uint256 accountBalance = balanceOf[msg.sender];
        require(
            accountBalance >= amount,
            "MyToken: burn amount exceeds balance"
        );

        balanceOf[msg.sender] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    // ==== Fonction interne de transfert avec vérifs de sécurité ====

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "MyToken: transfer from the zero address");
        require(recipient != address(0), "MyToken: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(
            senderBalance >= amount,
            "MyToken: transfer amount exceeds balance"
        );

        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

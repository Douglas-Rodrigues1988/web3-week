// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct Bet {
    uint amount;     
    uint candidate;
    uint timestamp;
    bool claimed;    // Alterado para 'bool' para indicar se a aposta foi reivindicada
}

struct Dispute {
    string candidate1;
    string candidate2;
    string image1;
    string image2;
    uint total1;
    uint total2;
    uint winner;
}

contract BetCandidate {
    Dispute public dispute;
    mapping (address => Bet) public allBets;

    address owner;
    uint fee = 1000; // 10% (escala de 4 zeros)
    uint public netPrize;
    uint public deadline; // Data limite para apostar

    constructor(uint _deadline) {
        owner = msg.sender;
        dispute = Dispute({
            candidate1: "D. Trump",
            candidate2: "K. Harris",
            image1: "http://bit.ly/3zmSfiA",
            image2: "http://bit.ly/4gF4mY",
            total1: 0,
            total2: 0,
            winner: 0
        });
        deadline = _deadline; // Inicializando a da limite    
    }

    function bet(uint candidate) external payable {
        require(candidate == 1 || candidate == 2, "Invalid candidate");
        require(msg.value > 0, "Invalid bet");
        require(dispute.winner == 0, "Dispute closed");
        require(block.timestamp <= deadline, "Betting period is over"); // Verificando se a data limite já passou

        // Verifica se já existe uma aposta e soma o valor da nova aposta
        Bet storage newBet = allBets[msg.sender];  // Usando 'storage' para modificar diretamente o valor no mapping
        newBet.amount += msg.value;  // Acumula o valor da aposta

        // Define o candidato e o timestamp
        newBet.candidate = candidate;
        newBet.timestamp = block.timestamp;

        // Atualiza o total de apostas para o candidato escolhido
        if(candidate == 1)
            dispute.total1 += msg.value;
        else
            dispute.total2 += msg.value;
    }

    function finish(uint winner) external {
        require(msg.sender == owner, "Invalid account");
        require(winner == 1 || winner == 2, "Invalid candidate");
        require(dispute.winner == 0, "Dispute closed");

        dispute.winner = winner;

        uint grossPrize = dispute.total1 + dispute.total2;
        uint comission = (grossPrize * fee) / 1e4;
        netPrize = grossPrize - comission;

        // Transferência segura da comissão para o dono do contrato
        (bool success, ) = payable(owner).call{value: comission}("");
        require(success, "Transfer failed");
    }

    function claim() external {
        Bet storage userBet = allBets[msg.sender];  // Usando 'storage' para modificar o valor de 'claimed'
        require(dispute.winner > 0 && dispute.winner == userBet.candidate && !userBet.claimed, "Invalid claim");

        // Calcula a proporção do prêmio individual com base no total apostado no candidato vencedor
        uint winnerAmount = dispute.winner == 1 ? dispute.total1 : dispute.total2;
        uint ratio = (userBet.amount * 1e4) / winnerAmount;
        uint individualPrize = netPrize * ratio / 1e4;

        // Marca a aposta como reivindicada e transfere o valor do prêmio
        userBet.claimed = true;
        payable(msg.sender).transfer(individualPrize);
    }  
}

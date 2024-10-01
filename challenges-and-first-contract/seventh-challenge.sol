// DESAFIO: Funções administrativas para permitir trocar foto e nome dos candidatos.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct Bet {
    uint amount;
    uint candidate;
    uint timestamp;
    uint claimed;
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

    address immutable owner; // Propriedade que armazena o dono do contrato
    uint public constant fee = 1000; //10% (escala de 4 zeros) - agora é constante
    uint public netPrize;
    uint public immutable deadline; // Data limite para apostar: 30 de novembro de 2024, às 00:00 UTC
    uint public comission; // Comissão armazenada para ser sacada depois

    // Novas variáveis para contabilizar o total de apostadores em cada candidato
    uint public totalBettorsCandidate1;
    uint public totalBettorsCandidate2;

    constructor() {
        owner = msg.sender; // Atribuindo o dono no construtor
        deadline = 1732924800; // Atribuindo a data limite no construtor

        dispute = Dispute({
            candidate1: "D. Trump",
            candidate2: "K. Harris",
            image1: "http://bit.ly/3zmSfiA",
            image2: "http://bit.ly/4gF4mY",
            total1: 0,
            total2: 0,
            winner: 0
        });    
    }

    function bet(uint candidate) external payable {
        require(candidate == 1 || candidate == 2, "Invalid candidate");
        require(msg.value > 0, "Invalid bet");
        require(dispute.winner == 0, "Dispute closed");
        require(block.timestamp <= deadline, "Betting period is over"); // Verificando se a data limite já passou
        require(allBets[msg.sender].amount == 0, "You have already placed a bet"); // Verificando se o usuário já apostou

        Bet memory newBet;
        newBet.amount = msg.value;
        newBet.candidate = candidate;
        newBet.timestamp = block.timestamp;

        allBets[msg.sender] = newBet;

        if(candidate == 1) {
            dispute.total1 += msg.value;
            totalBettorsCandidate1++; // Incrementando total de apostadores para o candidato 1
        } else {
            dispute.total2 += msg.value;
            totalBettorsCandidate2++; // Incrementando total de apostadores para o candidato 2
        }
    }

    function finish(uint winner) external {
        require(msg.sender == owner, "Invalid account");
        require(winner == 1 || winner == 2, "Invalid candidate");
        require(dispute.winner == 0, "Dispute closed");
        require(block.timestamp >= deadline, "Cannot finalize before deadline"); // Verificando se a data atual é após a deadline

        dispute.winner = winner;

        uint grossPrize = dispute.total1 + dispute.total2;
        comission = (grossPrize * fee) / 1e4; // Armazenando comissão
        netPrize = grossPrize - comission;     // Calculando o prêmio líquido
    }

    // Função para sacar a comissão separadamente
    function withdrawComission() external {
        require(msg.sender == owner, "Only owner can withdraw the commission");
        require(comission > 0, "No commission to withdraw");

        uint comissionToWithdraw = comission;
        comission = 0; // Resetar comissão para evitar saque duplo
        payable(owner).transfer(comissionToWithdraw);
    }

    function claim() external {
        Bet memory userBet = allBets[msg.sender];
        require(dispute.winner > 0 && dispute.winner == userBet.candidate && userBet.claimed == 0, "Invalid claim");

        uint winnerAmount = dispute.winner == 1 ? dispute.total1 : dispute.total2;
        uint ratio = (userBet.amount * 1e4) / winnerAmount;
        uint individualPrize = netPrize * ratio / 1e4;
        allBets[msg.sender].claimed = individualPrize;
        payable(msg.sender).transfer(individualPrize);
    }  

    // Função para atualizar os nomes dos candidatos
    function updateCandidateNames(string calldata _candidate1, string calldata _candidate2) external {
        require(msg.sender == owner, "Only owner can update candidate names"); // Apenas o dono pode atualizar
        dispute.candidate1 = _candidate1; // Atualizando o nome do candidato 1
        dispute.candidate2 = _candidate2; // Atualizando o nome do candidato 2
    }

    // Função para atualizar as imagens dos candidatos
    function updateCandidateImages(string calldata _image1, string calldata _image2) external {
        require(msg.sender == owner, "Only owner can update candidate images"); // Apenas o dono pode atualizar
        dispute.image1 = _image1; // Atualizando a imagem do candidato 1
        dispute.image2 = _image2; // Atualizando a imagem do candidato 2
    }
}

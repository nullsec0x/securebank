package com.banking.system.service;

import com.banking.system.entity.Account;
import com.banking.system.entity.Transaction;
import com.banking.system.repository.TransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;

@Service
@Transactional
public class TransactionService {
    
    @Autowired
    private TransactionRepository transactionRepository;
    
    @Autowired
    private AccountService accountService;
    
    public Transaction createTransaction(Long accountId, BigDecimal amount, 
                                         Transaction.TransactionType type) {
        Account account = accountService.getAccountById(accountId);
        
        if (type == Transaction.TransactionType.DEPOSIT) {
            accountService.deposit(accountId, amount);
        } else {
            accountService.withdraw(accountId, amount);
        }
        
        Transaction transaction = new Transaction(amount, type, account);
        return transactionRepository.save(transaction);
    }
    
    public List<Transaction> getTransactionsByAccountId(Long accountId) {
        return transactionRepository.findByAccountIdOrderByTimestampDesc(accountId);
    }
    
    public List<Transaction> getTransactionsByUserId(Long userId) {
        return transactionRepository.findByAccount_User_IdOrderByTimestampDesc(userId);
    }
    
    public List<Transaction> getAllTransactions() {
        return transactionRepository.findAll();
    }
}

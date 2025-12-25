package com.banking.system.service;

import com.banking.system.entity.Account;
import com.banking.system.entity.User;
import com.banking.system.repository.AccountRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class AccountService {
    
    @Autowired
    private AccountRepository accountRepository;
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private LogService logService;
    
    public Account createAccount(Long userId) {
        User user = userService.getUserById(userId);
        
        String accountNumber;
        do {
            accountNumber = "ACC" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (accountRepository.existsByAccountNumber(accountNumber));
        
        Account account = new Account(accountNumber, user);
        return accountRepository.save(account);
    }
    
    public Account getAccountById(Long id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Account not found"));
    }
    
    public Account getAccountByNumber(String accountNumber) {
        return accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new RuntimeException("Account not found"));
    }
    
    public List<Account> getAccountsByUserId(Long userId) {
        return accountRepository.findByUserId(userId);
    }
    
    public List<Account> getAllAccounts() {
        return accountRepository.findAll();
    }
    
    public Account deposit(Long accountId, BigDecimal amount) {
        Account account = getAccountById(accountId);
        account.setBalance(account.getBalance().add(amount));
        return accountRepository.save(account);
    }
    
    public Account withdraw(Long accountId, BigDecimal amount) {
        Account account = getAccountById(accountId);
        
        if (account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficient balance");
        }
        
        account.setBalance(account.getBalance().subtract(amount));
        return accountRepository.save(account);
    }
    
    public void deleteAccount(Long id) {
        Account account = getAccountById(id);
        
        // Check if account has balance
        if (account.getBalance().compareTo(BigDecimal.ZERO) > 0) {
            throw new RuntimeException("Cannot delete account with balance > 0. Withdraw funds first.");
        }
        
        accountRepository.deleteById(id);
        
        // Log the action
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        User user = userService.getUserByUsername(username);
        logService.createLog(username + " deleted account: " + account.getAccountNumber(), user);
    }
}

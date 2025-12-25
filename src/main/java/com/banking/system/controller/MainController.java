package com.banking.system.controller;

import com.banking.system.dto.LoginRequest;
import com.banking.system.dto.TransactionRequest;
import com.banking.system.entity.*;
import com.banking.system.service.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import java.math.BigDecimal;
import java.util.List;

@Controller
public class MainController {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private AccountService accountService;
    
    @Autowired
    private TransactionService transactionService;
    
    @Autowired
    private LogService logService;
    
    @GetMapping("/")
    public String home() {
        return "redirect:/dashboard";
    }
    
    @GetMapping("/login")
    public String loginPage(Model model) {
        model.addAttribute("loginRequest", new LoginRequest());
        return "login";
    }
    
    @GetMapping("/dashboard")
    public String dashboard() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        
        User user = userService.getUserByUsername(username);
        
        if (user.getRole() == User.Role.ADMIN) {
            return "redirect:/admin/dashboard";
        } else {
            return "redirect:/user/dashboard";
        }
    }
    
    @GetMapping("/admin/dashboard")
    public String adminDashboard(Model model) {
        List<User> users = userService.getAllUsers();
        List<Account> accounts = accountService.getAllAccounts();
        List<Transaction> transactions = transactionService.getAllTransactions();
        
        model.addAttribute("users", users);
        model.addAttribute("accounts", accounts);
        model.addAttribute("transactions", transactions);
        model.addAttribute("totalUsers", users.size());
        model.addAttribute("totalAccounts", accounts.size());
        
        return "admin-dashboard";
    }
    
    @GetMapping("/user/dashboard")
    public String userDashboard(Model model) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        
        User user = userService.getUserByUsername(username);
        List<Account> accounts = accountService.getAccountsByUserId(user.getId());
        List<Transaction> transactions = transactionService.getTransactionsByUserId(user.getId());
        
        model.addAttribute("user", user);
        model.addAttribute("accounts", accounts);
        model.addAttribute("transactions", transactions);
        
        return "user-dashboard";
    }
    
    @GetMapping("/transactions")
    public String transactionForm(Model model) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        
        User user = userService.getUserByUsername(username);
        List<Account> accounts = accountService.getAccountsByUserId(user.getId());
        
        model.addAttribute("transactionRequest", new TransactionRequest());
        model.addAttribute("accounts", accounts);
        model.addAttribute("transactionTypes", Transaction.TransactionType.values());
        
        return "transaction-form";
    }
    
    @PostMapping("/transactions")
    public String processTransaction(@Valid @ModelAttribute TransactionRequest request,
                                     BindingResult result,
                                     Model model,
                                     RedirectAttributes redirectAttributes) {
        if (result.hasErrors()) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();
            User user = userService.getUserByUsername(username);
            List<Account> accounts = accountService.getAccountsByUserId(user.getId());
            
            model.addAttribute("accounts", accounts);
            model.addAttribute("transactionTypes", Transaction.TransactionType.values());
            return "transaction-form";
        }
        
        try {
            Transaction.TransactionType type = Transaction.TransactionType.valueOf(request.getType().toUpperCase());
            transactionService.createTransaction(request.getAccountId(), request.getAmount(), type);
            
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();
            User user = userService.getUserByUsername(username);
            logService.createLog(username + " performed " + type + " of MAD " + request.getAmount(), user);
            
            redirectAttributes.addFlashAttribute("successMessage", 
    type + " of MAD " + request.getAmount() + " completed successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error: " + e.getMessage());
        }
        
        return "redirect:/transactions";
    }
    
    @GetMapping("/admin/logs")
    public String viewLogs(Model model) {
        List<Log> logs = logService.getAllLogs();
        model.addAttribute("logs", logs);
        return "admin-logs";
    }
    
    @GetMapping("/admin/create-user")
    public String createUserForm(Model model) {
        model.addAttribute("user", new User());
        model.addAttribute("roles", User.Role.values());
        return "admin-create-user";
    }
    
    @PostMapping("/admin/create-user")
    public String createUser(@ModelAttribute User user, RedirectAttributes redirectAttributes) {
        try {
            userService.createUser(user.getUsername(), user.getPassword(), user.getRole());
            redirectAttributes.addFlashAttribute("successMessage", "User created successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error: " + e.getMessage());
        }
        return "redirect:/admin/dashboard";
    }
    
    @PostMapping("/admin/create-account")
    public String createAccount(@RequestParam Long userId, RedirectAttributes redirectAttributes) {
        try {
            accountService.createAccount(userId);
            redirectAttributes.addFlashAttribute("successMessage", "Account created successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error: " + e.getMessage());
        }
        return "redirect:/admin/dashboard";
    }
    
    // ADD THIS METHOD: Delete user
    @PostMapping("/admin/delete-user")
    public String deleteUser(@RequestParam Long userId, RedirectAttributes redirectAttributes) {
        try {
            userService.deleteUser(userId);
            redirectAttributes.addFlashAttribute("successMessage", "User deleted successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error: " + e.getMessage());
        }
        return "redirect:/admin/dashboard";
    }
    
    // ADD THIS METHOD: Delete account
    @PostMapping("/user/delete-account")
    public String deleteAccount(@RequestParam Long accountId, RedirectAttributes redirectAttributes) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();
            User user = userService.getUserByUsername(username);
            
            Account account = accountService.getAccountById(accountId);
            if (!account.getUser().getId().equals(user.getId())) {
                throw new RuntimeException("You don't own this account");
            }
            
            accountService.deleteAccount(accountId);
            redirectAttributes.addFlashAttribute("successMessage", "Account deleted successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error: " + e.getMessage());
        }
        return "redirect:/user/dashboard";
    }
    
    @GetMapping("/access-denied")
    public String accessDenied() {
        return "access-denied";
    }
}

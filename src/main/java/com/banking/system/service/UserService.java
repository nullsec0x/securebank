package com.banking.system.service;

import com.banking.system.entity.User;
import com.banking.system.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;

@Service
@Transactional
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private LogService logService;
    
    public User createUser(String username, String password, User.Role role) {
        if (userRepository.existsByUsername(username)) {
            System.out.println("ERROR: Username already exists: " + username);
            throw new RuntimeException("Username already exists");
        }
        
        System.out.println("=== UserService.createUser() called ===");
        System.out.println("Username: " + username);
        System.out.println("Raw password: " + password);
        System.out.println("Role: " + role);
        
        String encodedPassword = passwordEncoder.encode(password);
        System.out.println("Encoded password: " + encodedPassword);
        System.out.println("Is BCrypt hash (starts with $2a$)? " + encodedPassword.startsWith("$2a$"));
        System.out.println("Password length: " + encodedPassword.length());
        
        User user = new User(username, encodedPassword, role);
        User savedUser = userRepository.save(user);
        
        System.out.println("User saved successfully!");
        System.out.println("User ID: " + savedUser.getId());
        System.out.println("=== UserService.createUser() finished ===\n");
        
        return savedUser;
    }
    
    public List<User> getAllUsers() {
        List<User> users = userRepository.findAll();
        System.out.println("=== UserService.getAllUsers() ===");
        System.out.println("Found " + users.size() + " users");
        for (User user : users) {
            System.out.println("  - " + user.getUsername() + " (ID: " + user.getId() + 
                             ", Role: " + user.getRole() + 
                             ", Password hash: " + user.getPassword().substring(0, Math.min(20, user.getPassword().length())) + "...)");
        }
        return users;
    }
    
    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> {
                    System.out.println("ERROR: User not found with ID: " + id);
                    return new RuntimeException("User not found");
                });
    }
    
    public User getUserByUsername(String username) {
        System.out.println("=== UserService.getUserByUsername() ===");
        System.out.println("Looking for user: " + username);
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> {
                    System.out.println("ERROR: User not found: " + username);
                    return new RuntimeException("User not found");
                });
        
        System.out.println("Found user: " + user.getUsername());
        System.out.println("User ID: " + user.getId());
        System.out.println("User role: " + user.getRole());
        System.out.println("Password hash: " + user.getPassword());
        System.out.println("Is BCrypt hash? " + user.getPassword().startsWith("$2a$"));
        
        return user;
    }
    
    public void deleteUser(Long id) {
        System.out.println("=== UserService.deleteUser() ===");
        System.out.println("Attempting to delete user ID: " + id);
        
        User user = getUserById(id);
        
        // Don't allow deleting admin users
        if (user.getRole() == User.Role.ADMIN) {
            System.out.println("ERROR: Cannot delete ADMIN user: " + user.getUsername());
            throw new RuntimeException("Cannot delete ADMIN users");
        }
        
        // Check if user has accounts with balance > 0
        boolean hasBalance = user.getAccounts().stream()
            .anyMatch(account -> account.getBalance().compareTo(BigDecimal.ZERO) > 0);
        
        if (hasBalance) {
            System.out.println("ERROR: User has account balance > 0: " + user.getUsername());
            throw new RuntimeException("Cannot delete user with account balance > 0");
        }
        
        userRepository.deleteById(id);
        System.out.println("User deleted successfully: " + user.getUsername());
        
        // Log the action
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated()) {
                String adminUsername = auth.getName();
                User admin = getUserByUsername(adminUsername);
                logService.createLog("Admin " + adminUsername + " deleted user: " + user.getUsername(), admin);
                System.out.println("Log created for deletion");
            }
        } catch (Exception e) {
            System.out.println("Warning: Could not create log entry: " + e.getMessage());
        }
    }
    
    public void updateUserRole(Long id, User.Role role) {
        System.out.println("=== UserService.updateUserRole() ===");
        System.out.println("Updating user ID " + id + " to role: " + role);
        
        User user = getUserById(id);
        user.setRole(role);
        userRepository.save(user);
        
        System.out.println("User role updated successfully");
    }
    
    // Debug method to check all users' passwords
    public void debugAllUsers() {
        System.out.println("=== DEBUG: Checking all users ===");
        List<User> users = userRepository.findAll();
        for (User user : users) {
            System.out.println("User: " + user.getUsername() + 
                             " | ID: " + user.getId() + 
                             " | Role: " + user.getRole() + 
                             " | Password: " + user.getPassword() +
                             " | Is BCrypt: " + user.getPassword().startsWith("$2a$"));
            
            // Try to verify password
            if (user.getPassword().startsWith("$2a$")) {
                System.out.println("  ✓ Password is BCrypt encoded");
            } else {
                System.out.println("  ⚠ Password is NOT BCrypt encoded!");
                System.out.println("  Password starts with: " + user.getPassword().substring(0, Math.min(10, user.getPassword().length())));
            }
        }
        System.out.println("Total users: " + users.size());
    }
}
